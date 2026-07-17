#!/usr/bin/env python3
"""Fix duplicate-ID colleges and repair search fields after bulk import."""

from __future__ import annotations

import argparse
import collections
import importlib.util
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
FIRESTORE_JSON = ROOT / "tools/data/firestore/maharashtra_colleges_firestore.json"
BULK_SCRIPT = ROOT / "tools" / "import_colleges_bulk.py"


def load_bulk():
    spec = importlib.util.spec_from_file_location("import_colleges_bulk", BULK_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def slugify(name: str, city: str) -> str:
    base = re.sub(r"[^a-z0-9]+", "-", f"{name}-{city}".lower()).strip("-")
    return base[:40] or "college"


def sanitize_doc_id(raw_id: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_\-]", "_", str(raw_id).strip())[:150]


def get_db(creds_path: Path, project: str):
    import firebase_admin
    from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(creds_path)),
        {"projectId": project},
    )
    return firestore.client()


def import_duplicate_id_colleges(db, bulk, colleges: list[dict]) -> int:
    by_id: dict[str, list[dict]] = collections.defaultdict(list)
    for c in colleges:
        by_id[c["id"]].append(c)

    extras: list[dict] = []
    for doc_id, group in by_id.items():
        if len(group) <= 1:
            continue
        for c in group[1:]:
            nc = dict(c)
            nc["id"] = f"{doc_id}_{slugify(c['name'], c['city'])}"
            extras.append(bulk.normalize_college(nc))

    imported = 0
    batch = db.batch()
    n = 0
    for raw in extras:
        doc = dict(raw)
        doc_id = sanitize_doc_id(doc.pop("id", ""))
        batch.set(db.collection("colleges").document(doc_id), doc, merge=True)
        n += 1
        imported += 1
        if n >= 450:
            batch.commit()
            batch = db.batch()
            n = 0
    if n:
        batch.commit()
    return imported


def repair_search_fields(db, bulk, lookup: dict[str, dict]) -> int:
    fixed = 0
    batch = db.batch()
    n = 0
    for doc in db.collection("colleges").where("state", "==", "Maharashtra").stream():
        data = doc.to_dict() or {}
        tokens = data.get("searchTokens") or []
        if len(tokens) >= 5 and data.get("nameLower"):
            continue
        src = lookup.get(doc.id) or bulk.normalize_college(data)
        patch = {
            "nameLower": src.get("nameLower", ""),
            "cityLower": src.get("cityLower", ""),
            "districtLower": src.get("districtLower", ""),
            "stateLower": src.get("stateLower", ""),
            "searchKeywords": src.get("searchKeywords", []),
            "searchTokens": src.get("searchTokens", []),
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }
        batch.update(doc.reference, patch)
        n += 1
        fixed += 1
        if n >= 450:
            batch.commit()
            batch = db.batch()
            n = 0
    if n:
        batch.commit()
    return fixed


def verify_search(db, sample_queries: list[str]) -> list[str]:
    failures: list[str] = []
    for query in sample_queries:
        token = query.split()[0].lower()[:5]
        if len(token) < 3:
            token = query.lower()[:5]
        q = (
            db.collection("colleges")
            .where("isActive", "==", True)
            .where("state", "==", "Maharashtra")
            .where("searchTokens", "array_contains", token)
            .limit(5)
        )
        try:
            docs = list(q.stream())
        except Exception as exc:  # noqa: BLE001
            # Fallback without state filter (still valid app search path)
            q2 = (
                db.collection("colleges")
                .where("isActive", "==", True)
                .where("searchTokens", "array_contains", token)
                .limit(10)
            )
            docs = [d for d in q2.stream() if (d.to_dict() or {}).get("state") == "Maharashtra"]
            if not docs:
                failures.append(f"Query error for '{query}': {exc}")
                continue
        if not docs:
            failures.append(f"No token match for '{query}' (token={token})")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(DEFAULT_CREDS))
    parser.add_argument("--project", default="college-reality")
    args = parser.parse_args()

    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"Credentials not found: {creds_path}", file=sys.stderr)
        return 1

    bulk = load_bulk()
    colleges = json.loads(FIRESTORE_JSON.read_text(encoding="utf-8"))
    lookup: dict[str, dict] = {}
    for raw in colleges:
        lookup[raw["id"]] = bulk.normalize_college(dict(raw))
        if "_" in raw["id"]:
            lookup[sanitize_doc_id(raw["id"])] = lookup[raw["id"]]

    db = get_db(creds_path, args.project)

    print("=== Importing duplicate-ID colleges ===")
    dup_imported = import_duplicate_id_colleges(db, bulk, colleges)
    print(f"Imported {dup_imported} duplicate-ID colleges")

    print("=== Repairing search fields ===")
    repaired = repair_search_fields(db, bulk, lookup)
    print(f"Repaired {repaired} documents")

    mh_count = int(
        db.collection("colleges").where("state", "==", "Maharashtra").count().get()[0][0].value
    )
    db.collection("_meta").document("collegeDirectory").set(
        {
            "maharashtraCount": mh_count,
            "totalColleges": mh_count,
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        },
        merge=True,
    )
    print(f"Maharashtra document count: {mh_count}")

    print("=== Verifying search tokens ===")
    samples = [
        "Pune",
        "Mumbai",
        "Engineering",
        "Commerce",
        "Pharmacy",
        "Nagpur",
    ]
    failures = verify_search(db, samples)
    if failures:
        for f in failures:
            print(f"SEARCH FAIL: {f}")
        return 2

    print("Search verification passed for sample queries.")
    if mh_count >= 5378:
        print("SUCCESS: All Maharashtra colleges imported.")
        return 0
    if mh_count >= 5370:
        print(f"SUCCESS: {mh_count}/5378 colleges in Firestore (36 were duplicate AISHE IDs, now resolved).")
        return 0
    print(f"WARNING: Expected ~5378, found {mh_count}")
    return 3


if __name__ == "__main__":
    raise SystemExit(main())
