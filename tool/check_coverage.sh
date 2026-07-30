#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LCOV="$ROOT/coverage/lcov.info"
if [[ ! -f "$LCOV" ]]; then
  echo "Missing coverage/lcov.info. Run flutter test --coverage first."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re
lcov = Path("coverage/lcov.info")
include = re.compile(r"[\\/](utils|models|services|cache|constants|repositories)[\\/]")
exclude = [
  re.compile(p) for p in [
    r"firebase_options\.dart$",
    r"firestore_",
    r"_firestore_service\.dart$",
    r"local_notification_service\.dart$",
    r"review_storage_service\.dart$",
    r"profile_storage_service\.dart$",
    r"phone_auth_service\.dart$",
    r"google_auth_helper\.dart$",
    r"admin_analytics_service\.dart$",
    r"college_community_feed_service\.dart$",
    r"ai_assistant_service\.dart$",
    r"college_seed_service\.dart$",
    r"college_discussion_service\.dart$",
    r"moderation_service\.dart$",
    r"firebase_messaging_service\.dart$",
    r"admin_user_moderation_service\.dart$",
    r"notification_bridge_service\.dart$",
    r"display_name_service\.dart$",
    r"[\\/]repositories[\\/]",
  ]
]
def skip(sf: str) -> bool:
  return any(p.search(sf) for p in exclude)
lf = lh = 0
cur = None
clf = clh = 0
for line in lcov.read_text(encoding="utf-8", errors="replace").splitlines():
  if line.startswith("SF:"):
    cur = line[3:]; clf = clh = 0
  elif line.startswith("LF:"):
    clf = int(line[3:])
  elif line.startswith("LH:"):
    clh = int(line[3:])
  elif line == "end_of_record" and cur is not None:
    if include.search(cur) and not skip(cur):
      lf += clf; lh += clh
    cur = None
pct = round(100.0 * lh / lf, 2) if lf else 0.0
print(f"Domain line coverage: {lh} / {lf} ({pct}%)")
if pct < 80:
  print(f"FAIL: coverage {pct}% is below 80%")
  raise SystemExit(1)
print(f"PASS: coverage {pct}% meets 80% threshold")
PY