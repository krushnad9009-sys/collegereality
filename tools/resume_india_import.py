#!/usr/bin/env python3
"""Resume all-India import state-by-state with quota retries until 100% complete."""

from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
JSON_PATH = ROOT / "tools/data/firestore/india_colleges_firestore.json"

STATES = [
    "Uttar Pradesh", "Maharashtra", "Karnataka", "Tamil Nadu", "Andhra Pradesh",
    "Rajasthan", "Gujarat", "Madhya Pradesh", "Telangana", "Kerala", "Odisha",
    "West Bengal", "Punjab", "Haryana", "Chhatisgarh", "Bihar", "Assam",
    "Uttrakhand", "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Goa",
    "Delhi", "Chandigarh", "Puducherry", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Tripura", "Arunachal Pradesh", "Sikkim", "Andaman and Nicobar Islands",
    "Dadra and Nagar Haveli", "Lakshadweep", "Daman and Diu",
]

MAX_STATE_ATTEMPTS = 6
QUOTA_WAIT_BASE = 120


def run(cmd: list[str], label: str) -> int:
    print(f"  >> {label}")
    return subprocess.run(cmd, cwd=str(ROOT)).returncode


def import_state(state: str) -> bool:
    for attempt in range(1, MAX_STATE_ATTEMPTS + 1):
        print(f"\n=== Processing {state} (attempt {attempt}/{MAX_STATE_ATTEMPTS}) ===")
        rc = run(
            [sys.executable, str(ROOT / "tools" / "import_india_aishe.py"), "--state", state],
            f"process {state}",
        )
        if rc != 0:
            wait = QUOTA_WAIT_BASE * attempt
            print(f"WARN: process failed for {state}, waiting {wait}s...")
            time.sleep(wait)
            continue

        count = len(json.loads(JSON_PATH.read_text(encoding="utf-8")))
        if count == 0:
            print(f"  No colleges for {state}, skip")
            return True

        print(f"  Importing {count} colleges...")
        rc = run(
            [
                sys.executable,
                str(ROOT / "tools" / "import_colleges_bulk.py"),
                "--input", str(JSON_PATH),
                "--credentials", str(CREDS),
                "--project", "college-reality",
                "--delay", "1.0",
                "--verify-state", state,
            ],
            f"import {state}",
        )
        if rc == 0:
            print(f"SUCCESS: {state} imported")
            return True

        wait = QUOTA_WAIT_BASE * attempt
        print(f"WARN: import failed for {state}, waiting {wait}s before retry...")
        time.sleep(wait)

    print(f"FAILED: {state} after {MAX_STATE_ATTEMPTS} attempts")
    return False


def main() -> int:
    if not CREDS.exists():
        print(f"Missing credentials: {CREDS}", file=sys.stderr)
        return 1

    completed: list[str] = []
    failed: list[str] = []

    for state in STATES:
        if import_state(state):
            completed.append(state)
        else:
            failed.append(state)

    # Retry failed states once more at end
    if failed:
        print(f"\n=== Retrying {len(failed)} failed state(s) ===")
        retry_failed: list[str] = []
        for state in failed:
            if import_state(state):
                completed.append(state)
            else:
                retry_failed.append(state)
        failed = retry_failed

    print(f"\n=== Regenerating full-India JSON for post-import fix ===")
    run([sys.executable, str(ROOT / "tools" / "import_india_aishe.py")], "full india JSON")

    print("\n=== Running post-import fix ===")
    fix_rc = run(
        [
            sys.executable,
            str(ROOT / "tools" / "fix_india_import.py"),
            "--credentials", str(CREDS),
            "--project", "college-reality",
        ],
        "fix_india_import",
    )

    print(f"\n=== Summary ===")
    print(f"Completed states: {len(completed)}/{len(STATES)}")
    if failed:
        print(f"Failed states: {failed}")
    return 0 if not failed and fix_rc == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
