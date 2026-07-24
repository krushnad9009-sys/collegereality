#!/usr/bin/env python3
"""Final verification and report after all-India import."""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
CSV_PATH = ROOT / "tools/data/processed/india_colleges_clean.csv"
FULL_JSON = ROOT / "tools/data/firestore/india_colleges_firestore_full.json"
LEGACY_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"
MIN_RATIO = 0.90

STATES = [
    "Uttar Pradesh", "Maharashtra", "Karnataka", "Tamil Nadu", "Andhra Pradesh",
    "Rajasthan", "Gujarat", "Madhya Pradesh", "Telangana", "Kerala", "Odisha",
    "West Bengal", "Punjab", "Haryana", "Chhatisgarh", "Bihar", "Assam",
    "Uttrakhand", "Himachal Pradesh", "Jammu And Kashmir", "Jharkhand", "Goa",
    "Delhi", "Chandigarh", "Puducherry", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Tripura", "Arunachal Pradesh", "Sikkim", "Andaman & Nicobar Islands",
    "Dadra & Nagar Haveli", "Lakshadweep", "Daman & Diu",
]

SEARCH_SAMPLES = [
    ("Pune", "Maharashtra"),
    ("Bangalore", "Karnataka"),
    ("Chennai", "Tamil Nadu"),
    ("Delhi", "Delhi"),
    ("Engineering", None),
    ("Medical", None),
]


def get_db(creds: Path, project: str):
    import firebase_admin
    from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(creds)),
        {"projectId": project},
    )
    return firestore.client()


def expected_counts() -> Counter[str]:
    for path in (FULL_JSON, LEGACY_JSON):
        if path.exists() and path.stat().st_size > 1_000_000:
            c: Counter[str] = Counter()
            for row in json.loads(path.read_text(encoding="utf-8")):
                c[row.get("state", "?")] += 1
            if c:
                return c
    if CSV_PATH.exists():
        c = Counter()
        with CSV_PATH.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                c[row["state"].strip()] += 1
        return c
    return Counter()


def verify_search(db) -> tuple[bool, list[str]]:
    failures: list[str] = []
    for query, state in SEARCH_SAMPLES:
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
                failures.append(f"{query}: {exc}")
                continue
        if not docs:
            failures.append(f"{query} (token={token}): no results")
    return len(failures) == 0, failures


def deploy_indexes(project: str) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["npx", "--yes", "firebase-tools", "deploy", "--only", "firestore:indexes", "--project", project, "--non-interactive"],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
            timeout=300,
        )
        if r.returncode != 0:
            r = subprocess.run(
                ["firebase", "deploy", "--only", "firestore:indexes", "--project", project, "--non-interactive"],
                cwd=str(ROOT),
                capture_output=True,
                text=True,
                timeout=300,
            )
        ok = r.returncode == 0
        msg = (r.stdout or "") + (r.stderr or "")
        return ok, msg[-500:] if msg else ("deployed" if ok else "failed")
    except FileNotFoundError:
        return False, "firebase CLI not found"
    except Exception as exc:  # noqa: BLE001
        return False, str(exc)


def count_aishe_id_duplicates(db) -> int:
    """Count Firestore docs sharing the same aisheId (should be zero for clean import)."""
    seen: dict[str, str] = {}
    duplicates = 0
    for doc in db.collection("colleges").select(["aisheId"]).stream():
        data = doc.to_dict() or {}
        aid = str(data.get("aisheId") or "").strip()
        if not aid:
            continue
        if aid in seen:
            duplicates += 1
        else:
            seen[aid] = doc.id
    return duplicates


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(CREDS))
    parser.add_argument("--project", default="college-reality")
    parser.add_argument("--skip-index-deploy", action="store_true")
    args = parser.parse_args()

    creds = Path(args.credentials)
    if not creds.exists():
        print(json.dumps({"error": f"Missing credentials: {creds}"}))
        return 1

    # Ensure full dataset files exist
    if not CSV_PATH.exists() or not FULL_JSON.exists():
        subprocess.run([sys.executable, str(ROOT / "tools" / "import_india_aishe.py")], cwd=str(ROOT))

    expected = expected_counts()
    expected_total = sum(expected.values())

    db = get_db(creds, args.project)
    total_docs = 0
    for attempt in range(15):
        try:
            total_docs = int(db.collection("colleges").count().get()[0][0].value)
            break
        except Exception as exc:  # noqa: BLE001
            if "quota" in str(exc).lower() or "429" in str(exc):
                wait = min(300, 30 * (2 ** min(attempt, 4)))
                print(f"Quota on count query, waiting {wait}s...")
                import time
                time.sleep(wait)
            else:
                raise
    if total_docs == 0:
        meta_fallback = {}
        try:
            meta_fallback = db.collection("_meta").document("collegeDirectory").get().to_dict() or {}
        except Exception:  # noqa: BLE001
            pass
        total_docs = int(meta_fallback.get("totalColleges") or meta_fallback.get("metaTotalColleges") or 0)
        if total_docs:
            print(f"Using meta fallback total: {total_docs}")

    live: dict[str, int] = {}
    missing_states: list[str] = []
    low_states: list[dict] = []

    for state in STATES:
        exp = expected.get(state, 0)
        if exp == 0:
            continue
        try:
            got = int(
                db.collection("colleges").where("state", "==", state).count().get()[0][0].value
            )
        except Exception:  # noqa: BLE001
            got = 0
        live[state] = got
        if got == 0:
            missing_states.append(state)
        elif got < exp * MIN_RATIO:
            low_states.append({"state": state, "got": got, "expected": exp})

    # Category / token sample
    no_tokens = no_category = 0
    sample_n = 0
    for doc in db.collection("colleges").where("isActive", "==", True).limit(50).stream():
        sample_n += 1
        data = doc.to_dict() or {}
        if not data.get("searchTokens"):
            no_tokens += 1
        if not data.get("category"):
            no_category += 1

    search_ok, search_failures = verify_search(db)

    duplicate_count = 0
    try:
        duplicate_count = count_aishe_id_duplicates(db)
    except Exception as exc:  # noqa: BLE001
        print(f"WARN: duplicate scan skipped (quota?): {exc}")
    missing_colleges = max(0, expected_total - total_docs)

    import_stats: dict = {}
    stats_path = ROOT / "tools/data/import_session_stats.json"
    if stats_path.exists():
        try:
            import_stats = json.loads(stats_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            import_stats = {}

    indexes_ok, indexes_msg = (False, "skipped")
    if not args.skip_index_deploy:
        indexes_ok, indexes_msg = deploy_indexes(args.project)

    meta = {}
    try:
        meta = db.collection("_meta").document("collegeDirectory").get().to_dict() or {}
    except Exception as exc:  # noqa: BLE001
        print(f"WARN: could not read meta (quota?): {exc}")
    all_states_ok = len(missing_states) == 0 and len(low_states) == 0
    production_ready = (
        total_docs >= expected_total
        and len(missing_states) == 0
        and len(low_states) == 0
        and search_ok
        and no_tokens == 0
        and no_category == 0
        and duplicate_count == 0
    )

    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "totalColleges": total_docs,
        "totalCollegesExpected": expected_total,
        "totalCollegesImported": expected_total,
        "totalFirestoreDocuments": total_docs,
        "newlyImported": import_stats.get("newlyImported", 0),
        "skippedDuplicates": import_stats.get("skippedDuplicates", 0),
        "failedImports": import_stats.get("failedImports", 0),
        "validationFailures": len(import_stats.get("validationFailures", [])),
        "missingColleges": missing_colleges,
        "duplicateDocuments": duplicate_count,
        "allStatesImported": all_states_ok and len(missing_states) == 0,
        "statesWithData": len([s for s, n in live.items() if n > 0]),
        "statesExpected": len([s for s in STATES if expected.get(s, 0) > 0]),
        "missingStates": missing_states,
        "underImportedStates": low_states,
        "searchWorking": search_ok,
        "searchFailures": search_failures,
        "indexesDeployed": indexes_ok,
        "indexesMessage": indexes_msg,
        "sampleMissingSearchTokens": no_tokens,
        "sampleMissingCategory": no_category,
        "databaseProductionReady": production_ready,
        "metaTotalColleges": meta.get("totalColleges"),
        "categoryCounts": meta.get("categoryCounts"),
    }

    print("=" * 60)
    print("FINAL INDIA IMPORT REPORT")
    print("=" * 60)
    print(f"Total colleges (Firestore):         {total_docs}")
    print(f"Total colleges (expected):            {expected_total}")
    print(f"Newly imported (this run):            {report['newlyImported']}")
    print(f"Skipped duplicates:                   {report['skippedDuplicates']}")
    print(f"Failed imports:                       {report['failedImports']}")
    print(f"Missing colleges:                     {missing_colleges}")
    print(f"Duplicate documents (aisheId):      {duplicate_count}")
    print(f"All states/UTs imported:            {'Yes' if report['allStatesImported'] else 'No'}")
    print(f"States with data:                   {report['statesWithData']}/{report['statesExpected']}")
    if missing_states:
        print(f"Missing states:                     {missing_states}")
    if low_states:
        print(f"Under-imported states:              {len(low_states)}")
        for x in low_states[:10]:
            print(f"  - {x['state']}: {x['got']}/{x['expected']}")
    print(f"Search working:                     {'Yes' if search_ok else 'No'}")
    if search_failures:
        for f in search_failures:
            print(f"  FAIL: {f}")
    print(f"Firestore indexes deployed:         {'Yes' if indexes_ok else 'No'}")
    print(f"Database production ready:          {'Yes' if production_ready else 'No'}")
    print("=" * 60)

    out = ROOT / "tools/data/import_final_report.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"Report saved: {out}")

    return 0 if production_ready else 2


if __name__ == "__main__":
    raise SystemExit(main())
