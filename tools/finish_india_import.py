#!/usr/bin/env python3
"""Import only missing/under-imported states, then fix and verify."""

from __future__ import annotations

import csv
import json
import re
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
CSV_PATH = ROOT / "tools/data/processed/india_colleges_clean.csv"
FULL_JSON = ROOT / "tools/data/firestore/india_colleges_firestore_full.json"
LEGACY_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"
STATE_DIR = ROOT / "tools/data/firestore/states"
CHECKPOINT = ROOT / "tools/data/import_checkpoint.json"
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


def states_in_dataset() -> list[str]:
    """All states/UTs present in the AISHE JSON (source of truth for naming)."""
    keys = list(expected_counts().keys())
    return keys if keys else STATES


def ensure_full_json() -> None:
    if FULL_JSON.exists() and FULL_JSON.stat().st_size > 1_000_000:
        return
    if LEGACY_JSON.exists() and LEGACY_JSON.stat().st_size > 1_000_000:
        try:
            data = json.loads(LEGACY_JSON.read_text(encoding="utf-8"))
            if isinstance(data, list) and len(data) > 10_000:
                FULL_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
                print(f"Backed up full JSON from legacy file ({len(data)} colleges)")
                return
        except json.JSONDecodeError:
            pass
    print("Regenerating full-India JSON...")
    subprocess.run(
        [sys.executable, str(ROOT / "tools" / "import_india_aishe.py")],
        cwd=str(ROOT),
        check=True,
    )


def load_full_colleges() -> list[dict]:
    ensure_full_json()
    path = FULL_JSON if FULL_JSON.exists() else LEGACY_JSON
    return json.loads(path.read_text(encoding="utf-8"))


def expected_counts() -> Counter[str]:
    colleges = load_full_colleges()
    c: Counter[str] = Counter()
    for row in colleges:
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


def state_slug(state: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", state.lower()).strip("_")


def colleges_for_state(state: str) -> list[dict]:
    return [c for c in load_full_colleges() if c.get("state") == state]


def total_firestore_count() -> int:
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(str(CREDS)),
            {"projectId": "college-reality"},
        )
    db = firestore.client()
    return int(db.collection("colleges").count().get()[0][0].value)


def firestore_count(state: str) -> int:
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(str(CREDS)),
            {"projectId": "college-reality"},
        )
    db = firestore.client()
    return int(
        db.collection("colleges").where("state", "==", state).count().get()[0][0].value
    )


def save_checkpoint(pending: list[str], current_state: str, reason: str) -> None:
    """Persist resume point when quota or interruption stops the import."""
    expected = expected_counts()
    snapshot: dict[str, dict] = {}
    for state in pending:
        try:
            got = firestore_count(state)
        except Exception:  # noqa: BLE001
            got = -1
        snapshot[state] = {"got": got, "expected": expected.get(state, 0)}
    payload = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "reason": reason,
        "currentState": current_state,
        "pendingStates": pending,
        "stateSnapshot": snapshot,
    }
    CHECKPOINT.parent.mkdir(parents=True, exist_ok=True)
    CHECKPOINT.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"Checkpoint saved: {CHECKPOINT}")


def load_checkpoint_states() -> list[str]:
    if not CHECKPOINT.exists():
        return []
    try:
        data = json.loads(CHECKPOINT.read_text(encoding="utf-8"))
        return list(data.get("pendingStates") or [])
    except json.JSONDecodeError:
        return []


def order_pending(pending: list[str], priority: list[str]) -> list[str]:
    if not priority:
        return pending
    head = [s for s in priority if s in pending]
    tail = [s for s in pending if s not in head]
    return head + tail


def import_state(state: str, *, strict: bool) -> str:
    """Import missing colleges for one state. Returns ok|quota|failed."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_json = STATE_DIR / f"{state_slug(state)}.json"
    colleges = colleges_for_state(state)
    if not colleges:
        print(f"No colleges in full JSON for {state}")
        return "ok"
    state_json.write_text(json.dumps(colleges, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Prepared {len(colleges)} colleges for {state} -> {state_json.name}")

    for attempt in range(1, 7):
        print(f"\n=== Importing {state} (attempt {attempt}, {len(colleges)} docs) ===")
        rc = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tools" / "import_colleges_bulk.py"),
                "--input", str(state_json),
                "--credentials", str(CREDS),
                "--project", "college-reality",
                "--delay", "3.0",
                "--only-missing",
                "--repair-state",
                "--verify-state", state,
            ],
            cwd=str(ROOT),
        ).returncode
        if rc == 2:
            try:
                got = firestore_count(state)
                exp = expected_counts().get(state, len(colleges))
                print(f"Quota/limit hit during {state}: {got}/{exp} — stopping gracefully")
            except Exception as exc:  # noqa: BLE001
                print(f"Quota/limit hit during {state} (count unavailable): {exc}")
            return "quota"
        if rc == 0:
            got = firestore_count(state)
            exp = expected_counts().get(state, len(colleges))
            target = exp if strict else int(exp * MIN_RATIO)
            if got >= target:
                print(f"OK {state}: {got}/{exp}")
                return "ok"
            print(f"Under target after import {state}: {got}/{exp} (will retry if attempts remain)")
            if attempt >= 2 and got >= int(exp * MIN_RATIO):
                print(f"Accepting {state} at {got}/{exp} (>= {MIN_RATIO:.0%} threshold)")
                return "ok"
        if rc != 0 and rc != 2:
            wait = min(60, 30 * attempt)
            print(f"Retry after {wait}s...")
            time.sleep(wait)
        if rc == 1 and attempt >= 2:
            print("Repeated import failures — treating as quota/interrupt")
            return "quota"
    return "failed"


def main() -> int:
    if not CREDS.exists():
        print(f"Missing {CREDS}", file=sys.stderr)
        return 1

    # Reset per-run import stats
    stats_path = ROOT / "tools/data/import_session_stats.json"
    stats_path.write_text(
        json.dumps(
            {
                "newlyImported": 0,
                "skippedDuplicates": 0,
                "failedImports": 0,
                "validationFailures": [],
                "sessions": [],
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    ensure_full_json()
    expected = expected_counts()
    dataset_states = states_in_dataset()
    expected_total = sum(expected.values())
    checkpoint_priority = load_checkpoint_states()
    strict = bool(checkpoint_priority)
    pending: list[str] = []

    if checkpoint_priority:
        print(f"Resuming from checkpoint ({len(checkpoint_priority)} states) — skipping full scan")
        pending = [s for s in checkpoint_priority if s in dataset_states]
    else:
        for state in dataset_states:
            exp = expected.get(state, 0)
            if exp == 0:
                continue
            try:
                got = firestore_count(state)
            except Exception as exc:  # noqa: BLE001
                print(f"Count error {state}: {exc}")
                pending.append(state)
                continue
            target = exp if strict else int(exp * MIN_RATIO)
            if got < target:
                print(f"PENDING {state}: {got}/{exp}")
                pending.append(state)
            else:
                print(f"OK {state}: {got}/{exp}")

    pending = order_pending(pending, checkpoint_priority)
    if checkpoint_priority:
        print(f"Checkpoint priority: {checkpoint_priority}")

    if pending:
        print(f"\nImporting {len(pending)} pending state(s)...")
        failed: list[str] = []
        for state in pending:
            result = import_state(state, strict=strict)
            if result == "quota":
                remaining = pending[pending.index(state) :]
                save_checkpoint(remaining, state, "firebase_daily_quota")
                print("\n=== Quota reached — run again later to resume missing colleges only ===")
                subprocess.run(
                    [sys.executable, str(ROOT / "tools" / "final_import_report.py"), "--credentials", str(CREDS)],
                    cwd=str(ROOT),
                )
                return 0
            if result != "ok":
                failed.append(state)
        if failed:
            save_checkpoint(failed, failed[0], "import_failed")
            print(f"FAILED: {failed}")
            subprocess.run(
                [sys.executable, str(ROOT / "tools" / "final_import_report.py"), "--credentials", str(CREDS)],
                cwd=str(ROOT),
            )
            return 2

    total = total_firestore_count()
    if total < expected_total:
        remaining = [
            s for s in dataset_states
            if firestore_count(s) < expected.get(s, 0)
        ]
        if remaining:
            save_checkpoint(remaining, remaining[0], "incomplete_total")
            print(f"\nIncomplete: {total}/{expected_total} — pending {len(remaining)} state(s)")
            subprocess.run(
                [sys.executable, str(ROOT / "tools" / "final_import_report.py"), "--credentials", str(CREDS), "--skip-index-deploy"],
                cwd=str(ROOT),
            )
            return 0

    print("\n=== Post-import fix ===")
    subprocess.run(
        [sys.executable, str(ROOT / "tools" / "import_india_aishe.py")],
        cwd=str(ROOT),
    )
    fix_rc = subprocess.run(
        [
            sys.executable,
            str(ROOT / "tools" / "fix_india_import.py"),
            "--credentials",
            str(CREDS),
            "--skip-duplicates",
        ],
        cwd=str(ROOT),
    ).returncode

    print("\n=== Verify ===")
    verify_rc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "verify_india_import.py"), "--credentials", str(CREDS)],
        cwd=str(ROOT),
    ).returncode

    report_rc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "final_import_report.py"), "--credentials", str(CREDS)],
        cwd=str(ROOT),
    ).returncode

    if CHECKPOINT.exists():
        CHECKPOINT.unlink()
        print("Checkpoint cleared — import complete.")

    return 0 if fix_rc == 0 and verify_rc == 0 and report_rc == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
