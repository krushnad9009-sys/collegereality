#!/bin/bash
# Polls Firestore until the Spark-plan daily read quota recovers, then
# automatically launches the (already-fixed) 50-college web-search dry run
# and exits. Self-contained so it doesn't require the agent to be woken up
# repeatedly just to poll.

cd "$(dirname "$0")/.."
LOG=tools/data/wait_for_quota_log.txt
POLL_SECONDS=1800     # 30 min between checks
MAX_WAIT_SECONDS=97200 # 27 hours safety valve
elapsed=0

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') starting quota watch" >> "$LOG"

while true; do
  status=$(python - <<'EOF'
from google.cloud import firestore
from google.oauth2 import service_account
try:
    creds = service_account.Credentials.from_service_account_file("android/tools/serviceAccount.json")
    db = firestore.Client(credentials=creds, project="college-reality")
    db.collection("colleges").document("aishe_53").get()
    print("OK")
except Exception as e:
    print(f"BLOCKED:{type(e).__name__}")
EOF
)
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') probe: $status (elapsed=${elapsed}s)" >> "$LOG"

  if [ "$status" = "OK" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') quota recovered — launching corrected 50-college dry run" >> "$LOG"
    rm -f tools/data/image_enrichment_web_search_report.json
    python tools/enrich_college_images_web_search.py --target 50 --dry-run --report --workers 10 >> "$LOG" 2>&1
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') dry run finished, exiting watcher" >> "$LOG"
    exit 0
  fi

  if [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') gave up after ${MAX_WAIT_SECONDS}s — quota never recovered" >> "$LOG"
    exit 1
  fi

  powershell -Command "Start-Sleep -Seconds $POLL_SECONDS" > /dev/null 2>&1
  elapsed=$((elapsed + POLL_SECONDS))
done
