#!/usr/bin/env python3
"""Resume India import from checkpoint; auto-retry after Firestore quota resets."""

from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHECKPOINT = ROOT / "tools/data/import_checkpoint.json"
FINISH = ROOT / "tools/finish_india_import.py"
REPORT = ROOT / "tools/final_import_report.py"
QUOTA_WAIT_SEC = 30 * 60  # 30 minutes between quota retries
MAX_QUOTA_RETRIES = 48  # up to 24 hours of waiting


def has_checkpoint() -> bool:
    return CHECKPOINT.exists()


def is_complete() -> bool:
    if CHECKPOINT.exists():
        return False
    try:
        import json
        from collections import Counter
        from pathlib import Path

        full = ROOT / "tools/data/firestore/india_colleges_firestore_full.json"
        if not full.exists():
            return False
        expected = sum(Counter(r["state"] for r in json.loads(full.read_text(encoding="utf-8"))).values())
        import firebase_admin
        from firebase_admin import credentials, firestore

        creds = ROOT / "android/tools/serviceAccount.json"
        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(str(creds)), {"projectId": "college-reality"})
        total = int(firestore.client().collection("colleges").count().get()[0][0].value)
        return total >= expected
    except Exception:  # noqa: BLE001
        return False


def main() -> int:
    quota_retries = 0
    while True:
        print(f"\n{'=' * 60}\nRunning finish_india_import.py\n{'=' * 60}")
        rc = subprocess.run(
            [sys.executable, str(FINISH)],
            cwd=str(ROOT),
        ).returncode

        if is_complete():
            print("\nImport pipeline complete.")
            report_rc = subprocess.run(
                [sys.executable, str(REPORT), "--skip-index-deploy"],
                cwd=str(ROOT),
            ).returncode
            return 0 if report_rc == 0 else report_rc

        if has_checkpoint() or rc == 0:
            quota_retries += 1
            if quota_retries > MAX_QUOTA_RETRIES:
                print("Max quota retries exceeded.", file=sys.stderr)
                subprocess.run([sys.executable, str(REPORT), "--skip-index-deploy"], cwd=str(ROOT))
                return 2
            try:
                data = json.loads(CHECKPOINT.read_text(encoding="utf-8"))
                print(f"Checkpoint reason: {data.get('reason')} — pending: {data.get('pendingStates')}")
            except json.JSONDecodeError:
                pass
            print(f"Quota/interrupt — waiting {QUOTA_WAIT_SEC // 60} min before retry ({quota_retries}/{MAX_QUOTA_RETRIES})...")
            time.sleep(QUOTA_WAIT_SEC)
            continue

        if rc != 0:
            subprocess.run([sys.executable, str(REPORT), "--skip-index-deploy"], cwd=str(ROOT))
            return rc

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
