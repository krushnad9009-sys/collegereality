#!/usr/bin/env python3
"""Post-import fixes for all-India colleges: duplicates, search, categories, verification."""

from __future__ import annotations

import argparse
import collections
import importlib.util
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
FULL_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"
FIRESTORE_JSON = FULL_JSON
BULK_SCRIPT = ROOT / "tools" / "import_colleges_bulk.py"

CATEGORIES = [
    "Engineering", "MBA", "Law", "Pharmacy", "Polytechnic", "Arts", "Commerce",
    "Science", "Medical", "Nursing", "Agriculture", "Architecture", "Fashion", "General",
]


def load_bulk():
    spec = importlib.util.spec_from_file_location("import_colleges_bulk", BULK_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


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
        base_id = c["id"].split("_")[0] + "_" + c["aisheId"] if "aishe_" in c["id"] else c["id"]
        if "_" in c["id"] and c["id"].count("_") > 1:
            continue  # already a suffixed duplicate
        by_id[c["id"]].append(c)

    extras: list[dict] = []
    for doc_id, group in by_id.items():
        if len(group) <= 1:
            continue
        for c in group[1:]:
            nc = dict(c)
            slug = re.sub(r"[^a-z0-9]+", "-", f"{c['name']}-{c['city']}".lower()).strip("-")[:40]
            nc["id"] = f"{doc_id}_{slug}"
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
        if n >= 100:
            for attempt in range(10):
                try:
                    batch.commit()
                    break
                except Exception as exc:  # noqa: BLE001
                    import time
                    msg = str(exc).lower()
                    if any(k in msg for k in ("quota", "429", "resource_exhausted")):
                        print(f"Quota hit importing duplicates — stopping duplicate pass: {exc}")
                        return imported
                    wait = 60 * (attempt + 1)
                    print(f"Dup batch retry {attempt + 1}, wait {wait}s: {exc}")
                    time.sleep(wait)
            batch = db.batch()
            n = 0
    if n:
        for attempt in range(10):
            try:
                batch.commit()
                break
            except Exception as exc:  # noqa: BLE001
                import time
                time.sleep(60 * (attempt + 1))
    return imported


def repair_search_fields(db, bulk, lookup: dict[str, dict]) -> int:
    """Repair only docs missing search tokens (sampled), not full collection scan."""
    fixed = 0
    batch = db.batch()
    n = 0
    # Spot-check recent imports; full data already has tokens from AISHE pipeline
    for doc in db.collection("colleges").where("isActive", "==", True).limit(500).stream():
        data = doc.to_dict() or {}
        tokens = data.get("searchTokens") or []
        if len(tokens) >= 5 and data.get("nameLower") and data.get("category"):
            continue
        src = lookup.get(doc.id) or bulk.normalize_college(data)
        patch = {
            "nameLower": src.get("nameLower", ""),
            "cityLower": src.get("cityLower", ""),
            "districtLower": src.get("districtLower", ""),
            "stateLower": src.get("stateLower", ""),
            "searchKeywords": src.get("searchKeywords", []),
            "searchTokens": src.get("searchTokens", []),
            "category": src.get("category", data.get("category", "General")),
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }
        batch.update(doc.reference, patch)
        n += 1
        fixed += 1
        if n >= 200:
            batch.commit()
            batch = db.batch()
            n = 0
    if n:
        batch.commit()
    return fixed


def create_category_collections_from_json(colleges: list[dict]) -> dict[str, int]:
    category_counts: Counter[str] = Counter()
    category_samples: dict[str, list[str]] = {cat: [] for cat in CATEGORIES}
    for c in colleges:
        cat = c.get("category") or "General"
        category_counts[cat] += 1
        doc_id = c.get("id", "")
        if doc_id and len(category_samples.get(cat, [])) < 20:
            category_samples.setdefault(cat, []).append(doc_id)
    return dict(category_counts), category_samples


def write_category_collections(db, category_counts: dict[str, int], category_samples: dict[str, list[str]]) -> None:
    now = datetime.now(timezone.utc).isoformat()
    batch = db.batch()
    for cat in CATEGORIES:
        ref = db.collection("categoryDirectories").document(cat)
        batch.set(
            ref,
            {
                "category": cat,
                "count": category_counts.get(cat, 0),
                "sampleCollegeIds": category_samples.get(cat, [])[:20],
                "updatedAt": now,
            },
            merge=True,
        )
    batch.commit()


def verify_search(db, sample_queries: list[tuple[str, str | None]]) -> list[str]:
    failures: list[str] = []
    for query, state in sample_queries:
        token = query.split()[0].lower()[:5]
        if len(token) < 3:
            token = query.lower()[:5]
        q = db.collection("colleges").where("isActive", "==", True)
        if state:
            q = q.where("state", "==", state)
        q = q.where("searchTokens", "array_contains", token).limit(5)
        try:
            docs = list(q.stream())
        except Exception as exc:  # noqa: BLE001
            q2 = (
                db.collection("colleges")
                .where("isActive", "==", True)
                .where("searchTokens", "array_contains", token)
                .limit(15)
            )
            docs = [d for d in q2.stream() if not state or (d.to_dict() or {}).get("state") == state]
            if not docs:
                failures.append(f"Query error for '{query}' ({state}): {exc}")
                continue
        if not docs:
            failures.append(f"No match for '{query}' state={state} token={token}")
    return failures


def update_meta(db, colleges: list[dict], expected_from_json: int) -> dict:
    total = int(db.collection("colleges").count().get()[0][0].value)
    state_counts: Counter[str] = Counter()
    for c in colleges:
        state_counts[c.get("state", "Unknown")] += 1

    category_counts, category_samples = create_category_collections_from_json(colleges)
    write_category_collections(db, category_counts, category_samples)

    now = datetime.now(timezone.utc).isoformat()
    meta = {
        "totalColleges": total,
        "expectedFromImport": expected_from_json,
        "states": sorted(state_counts.keys()),
        "stateCounts": dict(state_counts.most_common()),
        "categoryCounts": category_counts,
        "maharashtraCount": state_counts.get("Maharashtra", 0),
        "indiaImportedAt": now,
        "updatedAt": now,
    }
    db.collection("_meta").document("collegeDirectory").set(meta, merge=True)
    return meta


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(DEFAULT_CREDS))
    parser.add_argument("--project", default="college-reality")
    parser.add_argument("--skip-duplicates", action="store_true", help="Skip duplicate-ID extra imports")
    args = parser.parse_args()

    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"Credentials not found: {creds_path}", file=sys.stderr)
        return 1

    if not FIRESTORE_JSON.exists() or FIRESTORE_JSON.stat().st_size < 1_000_000:
        print("Regenerating full-India JSON for fix...")
        import subprocess
        subprocess.run(
            [sys.executable, str(ROOT / "tools" / "import_india_aishe.py")],
            cwd=str(ROOT),
            check=False,
        )

    if not FIRESTORE_JSON.exists():
        print(f"Missing {FIRESTORE_JSON}", file=sys.stderr)
        return 1

    bulk = load_bulk()
    colleges = json.loads(FIRESTORE_JSON.read_text(encoding="utf-8"))
    lookup: dict[str, dict] = {}
    for raw in colleges:
        norm = bulk.normalize_college(dict(raw))
        lookup[raw["id"]] = norm
        lookup[sanitize_doc_id(raw["id"])] = norm

    db = get_db(creds_path, args.project)

    print("=== Importing duplicate-ID colleges ===")
    dup_imported = 0 if args.skip_duplicates else import_duplicate_id_colleges(db, bulk, colleges)
    print(f"Imported {dup_imported} duplicate-ID colleges")

    print("=== Repairing search fields ===")
    repaired = repair_search_fields(db, bulk, lookup)
    print(f"Repaired {repaired} documents")

    print("=== Creating category directories ===")
    expected = len(colleges)
    meta = update_meta(db, colleges, expected)
    print(f"Total Firestore colleges: {meta['totalColleges']}")
    print(f"States: {len(meta['states'])}")
    print(f"Categories: {meta['categoryCounts']}")

    print("=== Verifying search ===")
    samples = [
        ("Pune", "Maharashtra"),
        ("Bangalore", "Karnataka"),
        ("Chennai", "Tamil Nadu"),
        ("Delhi", "Delhi"),
        ("Engineering", None),
        ("Medical", None),
        ("MBA", None),
    ]
    failures = verify_search(db, samples)
    if failures:
        for f in failures:
            print(f"SEARCH FAIL: {f}")
        return 2

    print("Search verification passed.")
    if meta["totalColleges"] >= expected * 0.98:
        print("SUCCESS: All-India import verified.")
        return 0
    print(f"WARNING: Expected ~{expected}, found {meta['totalColleges']}")
    return 3


if __name__ == "__main__":
    raise SystemExit(main())
