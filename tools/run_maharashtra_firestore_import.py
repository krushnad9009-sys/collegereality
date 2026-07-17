#!/usr/bin/env python3
"""End-to-end Maharashtra AISHE pipeline: download -> clean -> Firestore import -> verify.

Usage:
  pip install firebase-admin requests
  $env:GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccount.json"  # or --credentials
  python tools/run_maharashtra_firestore_import.py
  python tools/run_maharashtra_firestore_import.py --skip-import   # process only
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AISHE_SCRIPT = ROOT / "tools" / "import_maharashtra_aishe.py"
BULK_SCRIPT = ROOT / "tools" / "import_colleges_bulk.py"
RAW_CSV = ROOT / "tools/data/raw/aishe_colleges_india.csv"
FIRESTORE_JSON = ROOT / "tools/data/firestore/maharashtra_colleges_firestore.json"

# Official AISHE mirror from data.gov.in OGD catalog (Institutions AISHE Survey).
AISHE_CSV_URL = (
    "https://raw.githubusercontent.com/PriyanKishoreMS/colleges-api/master/data/colleges.csv"
)
DEFAULT_PROJECT = "college-reality"
CREDENTIAL_CANDIDATES = [
    ROOT / "tools" / "serviceAccount.json",
    ROOT / "android" / "tools" / "serviceAccount.json",
    ROOT / "tools" / "college-reality-service-account.json",
]


def download_aishe_csv(dest: Path, force: bool = False) -> None:
    if dest.exists() and not force and dest.stat().st_size > 1_000_000:
        print(f"Using cached AISHE CSV ({dest.stat().st_size // 1024} KB)")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading AISHE colleges CSV from open-government mirror...")
    urllib.request.urlretrieve(AISHE_CSV_URL, dest)
    print(f"Downloaded {dest.stat().st_size // 1024} KB -> {dest}")


def load_aishe_module():
    spec = importlib.util.spec_from_file_location("import_maharashtra_aishe", AISHE_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def resolve_credentials(explicit: str | None) -> str | None:
    if explicit:
        p = Path(explicit)
        return str(p) if p.exists() else None
    import os

    env = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
    if env and Path(env).exists():
        return env
    for candidate in CREDENTIAL_CANDIDATES:
        if candidate.exists():
            return str(candidate)
    return None


def sanitize_doc_id(raw_id: str) -> str:
    doc_id = re.sub(r"[^a-zA-Z0-9_\-]", "_", raw_id.strip())
    return doc_id[:150] if doc_id else "college_unknown"


def import_to_firestore(
    json_path: Path,
    project: str,
    credentials_path: str | None,
) -> tuple[int, list[str]]:
    """Import colleges; returns (imported_count, errors)."""
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "firebase-admin"])
        import firebase_admin
        from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())

    if credentials_path:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred, {"projectId": project})
    else:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {"projectId": project})

    # Load bulk import helpers
    spec = importlib.util.spec_from_file_location("import_colleges_bulk", BULK_SCRIPT)
    bulk = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(bulk)

    db = firestore.client()
    colleges = json.loads(json_path.read_text(encoding="utf-8"))
    if not isinstance(colleges, list):
        raise ValueError("Firestore JSON must be an array")

    errors: list[str] = []
    batch_size = 450
    imported = 0
    expected_ids: list[str] = []

    for i in range(0, len(colleges), batch_size):
        chunk = colleges[i : i + batch_size]
        batch = db.batch()
        chunk_count = 0
        for raw in chunk:
            try:
                doc = bulk.normalize_college(dict(raw))
                doc_id = sanitize_doc_id(str(doc.pop("id", "") or doc.get("slug") or f"college_{imported}"))
                expected_ids.append(doc_id)
                batch.set(db.collection("colleges").document(doc_id), doc, merge=True)
                chunk_count += 1
            except Exception as exc:  # noqa: BLE001
                errors.append(f"prepare {raw.get('name', '?')}: {exc}")

        for attempt in range(3):
            try:
                batch.commit()
                imported += chunk_count
                print(f"Imported {imported}/{len(colleges)}")
                break
            except Exception as exc:  # noqa: BLE001
                if attempt == 2:
                    errors.append(f"batch {i}-{i + batch_size}: {exc}")
                    # Retry one-by-one
                    for raw in chunk:
                        try:
                            doc = bulk.normalize_college(dict(raw))
                            doc_id = sanitize_doc_id(
                                str(doc.pop("id", "") or doc.get("slug") or f"college_{imported}")
                            )
                            db.collection("colleges").document(doc_id).set(doc, merge=True)
                            imported += 1
                        except Exception as inner:  # noqa: BLE001
                            errors.append(f"single {raw.get('name', '?')}: {inner}")
                else:
                    print(f"Batch retry {attempt + 1} after: {exc}")

    now = datetime.now(timezone.utc).isoformat()
    db.collection("_meta").document("collegeDirectory").set(
        {
            "totalColleges": imported,
            "states": ["Maharashtra"],
            "updatedAt": now,
            "maharashtraImportedAt": now,
            "maharashtraCount": imported,
        },
        merge=True,
    )
    return imported, errors


def count_maharashtra_docs(project: str, credentials_path: str | None) -> int:
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        if credentials_path:
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred, {"projectId": project})
        else:
            cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred, {"projectId": project})

    db = firestore.client()
    q = db.collection("colleges").where("state", "==", "Maharashtra")
    result = q.count().get()
    return int(result[0][0].value)


def repair_search_fields(
    project: str,
    credentials_path: str | None,
    json_path: Path,
) -> int:
    """Ensure every Maharashtra doc has searchTokens and normalized fields."""
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        if credentials_path:
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred, {"projectId": project})
        else:
            cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred, {"projectId": project})

    spec = importlib.util.spec_from_file_location("import_colleges_bulk", BULK_SCRIPT)
    bulk = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(bulk)

    lookup = {}
    for raw in json.loads(json_path.read_text(encoding="utf-8")):
        doc_id = sanitize_doc_id(str(raw.get("id", "")))
        lookup[doc_id] = bulk.normalize_college(dict(raw))

    db = firestore.client()
    fixed = 0
    batch = db.batch()
    batch_n = 0

    for doc in db.collection("colleges").where("state", "==", "Maharashtra").stream():
        data = doc.to_dict() or {}
        tokens = data.get("searchTokens") or []
        name_lower = data.get("nameLower") or ""
        if tokens and name_lower:
            continue
        source = lookup.get(doc.id)
        if not source:
            source = bulk.normalize_college(data)
        patch = {
            "nameLower": source.get("nameLower", ""),
            "cityLower": source.get("cityLower", ""),
            "districtLower": source.get("districtLower", ""),
            "stateLower": source.get("stateLower", ""),
            "searchKeywords": source.get("searchKeywords", []),
            "searchTokens": source.get("searchTokens", []),
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }
        batch.update(doc.reference, patch)
        batch_n += 1
        fixed += 1
        if batch_n >= 450:
            batch.commit()
            batch = db.batch()
            batch_n = 0
            print(f"Repaired {fixed} search fields...")

    if batch_n:
        batch.commit()
    return fixed


def main() -> int:
    parser = argparse.ArgumentParser(description="Maharashtra AISHE Firestore pipeline")
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    parser.add_argument("--credentials", default=None, help="Firebase service account JSON")
    parser.add_argument("--skip-download", action="store_true")
    parser.add_argument("--skip-import", action="store_true")
    parser.add_argument("--force-download", action="store_true")
    parser.add_argument("--seed-limit", type=int, default=300)
    args = parser.parse_args()

    # 1. Download
    if not args.skip_download:
        download_aishe_csv(RAW_CSV, force=args.force_download)

    # 2. Process / clean / categorize
    print("\n=== Processing Maharashtra colleges ===")
    proc = subprocess.run(
        [
            sys.executable,
            str(AISHE_SCRIPT),
            "--input",
            str(RAW_CSV),
            "--seed-limit",
            str(args.seed_limit),
        ],
        cwd=str(ROOT),
    )
    if proc.returncode != 0:
        return proc.returncode

    if not FIRESTORE_JSON.exists():
        print(f"Missing output: {FIRESTORE_JSON}", file=sys.stderr)
        return 1

    expected = len(json.loads(FIRESTORE_JSON.read_text(encoding="utf-8")))
    print(f"\nFirestore JSON ready: {expected} Maharashtra colleges")

    if args.skip_import:
        print("Skipped Firestore import (--skip-import)")
        return 0

    creds = resolve_credentials(args.credentials)
    if not creds:
        print(
            "\nERROR: No Firebase service account found.\n"
            "Download from Firebase Console -> Project Settings -> Service Accounts,\n"
            "save as tools/serviceAccount.json, then re-run.\n"
            "Or set GOOGLE_APPLICATION_CREDENTIALS / --credentials path.",
            file=sys.stderr,
        )
        return 2

    print(f"\n=== Importing to Firestore ({args.project}) ===")
    try:
        imported, errors = import_to_firestore(FIRESTORE_JSON, args.project, creds)
    except Exception as exc:  # noqa: BLE001
        print(f"Import failed: {exc}", file=sys.stderr)
        return 3

    if errors:
        print(f"\nImport completed with {len(errors)} error(s):")
        for err in errors[:20]:
            print(f"  - {err}")
        if len(errors) > 20:
            print(f"  ... and {len(errors) - 20} more")

    # 3. Verify count
    print("\n=== Verifying document count ===")
    try:
        live_count = count_maharashtra_docs(args.project, creds)
    except Exception as exc:  # noqa: BLE001
        print(f"Count verification failed: {exc}", file=sys.stderr)
        live_count = -1

    print(f"Expected: {expected} | Firestore Maharashtra docs: {live_count}")

    # 4. Repair search fields if needed
    if live_count > 0:
        print("\n=== Repairing search tokens ===")
        try:
            repaired = repair_search_fields(args.project, creds, FIRESTORE_JSON)
            print(f"Repaired {repaired} documents missing search fields")
        except Exception as exc:  # noqa: BLE001
            print(f"Search repair warning: {exc}")

    if live_count == expected:
        print("\nSUCCESS: All Maharashtra colleges imported and verified.")
        return 0 if not errors else 4

    if live_count > 0 and live_count >= expected * 0.98:
        print("\nPARTIAL SUCCESS: >=98% imported. Re-run to fill gaps.")
        return 4

    print("\nWARNING: Count mismatch — check errors above and re-run import.")
    return 5


if __name__ == "__main__":
    raise SystemExit(main())
