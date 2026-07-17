#!/usr/bin/env python3
"""End-to-end all-India AISHE pipeline: download -> clean -> Firestore import -> verify.

Usage:
  pip install firebase-admin
  python tools/run_india_firestore_import.py
  python tools/run_india_firestore_import.py --exclude-state Maharashtra
  python tools/run_india_firestore_import.py --skip-import
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import subprocess
import sys
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AISHE_SCRIPT = ROOT / "tools" / "import_india_aishe.py"
BULK_SCRIPT = ROOT / "tools" / "import_colleges_bulk.py"
FIX_SCRIPT = ROOT / "tools" / "fix_india_import.py"
RAW_CSV = ROOT / "tools/data/raw/aishe_colleges_india.csv"
FIRESTORE_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"

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
    print("Downloading latest AISHE colleges CSV from open-government mirror...")
    urllib.request.urlretrieve(AISHE_CSV_URL, dest)
    print(f"Downloaded {dest.stat().st_size // 1024} KB -> {dest}")


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

    spec = importlib.util.spec_from_file_location("import_colleges_bulk", BULK_SCRIPT)
    bulk = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(bulk)

    db = firestore.client()
    colleges = json.loads(json_path.read_text(encoding="utf-8"))
    if not isinstance(colleges, list):
        raise ValueError("Firestore JSON must be an array")

    errors: list[str] = []
    batch_size = 200
    imported = 0

    for i in range(0, len(colleges), batch_size):
        chunk = colleges[i : i + batch_size]
        batch = db.batch()
        chunk_count = 0
        for raw in chunk:
            try:
                doc = bulk.normalize_college(dict(raw))
                doc_id = sanitize_doc_id(
                    str(doc.pop("id", "") or doc.get("slug") or f"college_{imported}")
                )
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

    return imported, errors


def count_total_docs(project: str, credentials_path: str | None) -> int:
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
    return int(db.collection("colleges").count().get()[0][0].value)


def main() -> int:
    parser = argparse.ArgumentParser(description="All-India AISHE Firestore pipeline")
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    parser.add_argument("--credentials", default=None)
    parser.add_argument("--skip-download", action="store_true")
    parser.add_argument("--skip-import", action="store_true")
    parser.add_argument("--force-download", action="store_true")
    parser.add_argument("--state", default=None, help="Import single state only")
    parser.add_argument("--exclude-state", default=None, help="Skip state already imported")
    parser.add_argument("--seed-limit", type=int, default=500)
    args = parser.parse_args()

    if not args.skip_download:
        download_aishe_csv(RAW_CSV, force=args.force_download)

    print("\n=== Processing all-India colleges ===")
    proc_args = [
        sys.executable,
        str(AISHE_SCRIPT),
        "--input",
        str(RAW_CSV),
        "--seed-limit",
        str(args.seed_limit),
    ]
    if args.state:
        proc_args.extend(["--state", args.state])
    if args.exclude_state:
        proc_args.extend(["--exclude-state", args.exclude_state])

    proc = subprocess.run(proc_args, cwd=str(ROOT))
    if proc.returncode != 0:
        return proc.returncode

    if not FIRESTORE_JSON.exists():
        print(f"Missing output: {FIRESTORE_JSON}", file=sys.stderr)
        return 1

    expected = len(json.loads(FIRESTORE_JSON.read_text(encoding="utf-8")))
    print(f"\nFirestore JSON ready: {expected} colleges")

    if args.skip_import:
        print("Skipped Firestore import (--skip-import)")
        return 0

    creds = resolve_credentials(args.credentials)
    if not creds:
        print(
            "\nERROR: No Firebase service account found.\n"
            "Save service account as tools/serviceAccount.json or android/tools/serviceAccount.json",
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

    print("\n=== Running post-import fixes (duplicates, search, categories) ===")
    fix_args = [
        sys.executable,
        str(FIX_SCRIPT),
        "--credentials",
        creds,
        "--project",
        args.project,
    ]
    fix_proc = subprocess.run(fix_args, cwd=str(ROOT))
    if fix_proc.returncode != 0:
        print("Fix script reported issues", file=sys.stderr)
        return fix_proc.returncode

    print("\nSUCCESS: All-India college import pipeline complete.")
    return 0 if not errors else 4


if __name__ == "__main__":
    raise SystemExit(main())
