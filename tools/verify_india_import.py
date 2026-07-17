#!/usr/bin/env python3
"""Verify all-India import completeness and production readiness."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
CSV_PATH = ROOT / "tools/data/processed/india_colleges_clean.csv"
FULL_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"

# Minimum docs per state to consider "imported" (allows small variance from dedupe)
MIN_RATIO = 0.90


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


def expected_from_csv() -> Counter[str]:
    counts: Counter[str] = Counter()
    if not CSV_PATH.exists():
        return counts
    with CSV_PATH.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            counts[row.get("state", "").strip()] += 1
    return counts


def firestore_state_counts(db) -> Counter[str]:
    counts: Counter[str] = Counter()
    # Paginate by state using distinct state values from CSV
    expected_states = list(expected_from_csv().keys())
    for state in expected_states:
        try:
            n = int(
                db.collection("colleges")
                .where("state", "==", state)
                .count()
                .get()[0][0]
                .value
            )
            if n > 0:
                counts[state] = n
        except Exception as exc:  # noqa: BLE001
            print(f"WARN: count failed for {state}: {exc}")
    return counts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(CREDS))
    parser.add_argument("--project", default="college-reality")
    args = parser.parse_args()

    creds = Path(args.credentials)
    if not creds.exists():
        print(f"Missing credentials: {creds}", file=sys.stderr)
        return 1

    # Ensure full JSON exists
    if not FULL_JSON.exists() or FULL_JSON.stat().st_size < 1_000_000:
        print("Regenerating full-India JSON...")
        import subprocess
        subprocess.run(
            [sys.executable, str(ROOT / "tools" / "import_india_aishe.py")],
            cwd=str(ROOT),
            check=False,
        )

    expected = expected_from_csv()
    if not expected and FULL_JSON.exists():
        colleges = json.loads(FULL_JSON.read_text(encoding="utf-8"))
        for c in colleges:
            expected[c.get("state", "?")] += 1

    db = get_db(creds, args.project)
    total = int(db.collection("colleges").count().get()[0][0].value)
    live = firestore_state_counts(db)

    missing: list[str] = []
    low: list[tuple[str, int, int]] = []
    for state, exp in expected.items():
        got = live.get(state, 0)
        if got == 0:
            missing.append(state)
        elif got < exp * MIN_RATIO:
            low.append((state, got, exp))

    print(f"Total Firestore colleges: {total}")
    print(f"Expected from CSV: {sum(expected.values())}")
    print(f"States in Firestore: {len(live)}/{len(expected)}")

    if missing:
        print(f"\nMissing states ({len(missing)}):")
        for s in missing:
            print(f"  - {s} (expected {expected[s]})")

    if low:
        print(f"\nUnder-imported states ({len(low)}):")
        for s, got, exp in low:
            print(f"  - {s}: {got}/{exp}")

    # Sample search + category check
    sample = db.collection("colleges").where("isActive", "==", True).limit(20).stream()
    no_tokens = no_cat = 0
    for doc in sample:
        data = doc.to_dict() or {}
        if not data.get("searchTokens"):
            no_tokens += 1
        if not data.get("category"):
            no_cat += 1

    print(f"\nSample check (20 docs): missing searchTokens={no_tokens}, missing category={no_cat}")

    meta = db.collection("_meta").document("collegeDirectory").get().to_dict() or {}
    print(f"Meta totalColleges: {meta.get('totalColleges')}")
    print(f"Meta categoryCounts keys: {len(meta.get('categoryCounts') or {})}")

    if not missing and not low and total >= sum(expected.values()) * MIN_RATIO:
        print("\nPRODUCTION READY: All states imported.")
        return 0
    print("\nNOT COMPLETE: Re-run resume_india_import.py for missing states.")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
