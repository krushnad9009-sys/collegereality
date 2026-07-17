#!/usr/bin/env python3
"""Wait for running import PID to finish, then run finish_india_import.py."""
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def pid_running(pid: int) -> bool:
    if sys.platform == "win32":
        r = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}"],
            capture_output=True, text=True,
        )
        return str(pid) in r.stdout
    import os
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def main() -> int:
    pid = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    if pid:
        print(f"Watching PID {pid}...")
        while pid_running(pid):
            time.sleep(60)
        print("Import process finished.")

    print("Running finish_india_import.py...")
    rc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "finish_india_import.py")],
        cwd=str(ROOT),
    ).returncode

    print("Running final_import_report.py...")
    report_rc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "final_import_report.py")],
        cwd=str(ROOT),
    ).returncode

    return 0 if rc == 0 and report_rc == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
