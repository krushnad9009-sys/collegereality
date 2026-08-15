#!/bin/bash
# Drives enrich_college_images_web_search.py toward the 700 target across
# multiple passes, tolerating transient Firestore quota errors by pausing
# and retrying rather than dying. Real writes (no --dry-run). Safe to
# interrupt/resume at any time — everything is checkpointed.

cd "$(dirname "$0")/.."
LOG=tools/data/image_enrichment_web_search_continuous_log.txt
TARGET=700
PASS_SLEEP=60        # seconds between passes
QUOTA_RETRY_SLEEP=900 # 15 min pause after a quota-exhaustion pass
MAX_PASSES=60

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') starting continuous web-search enrichment toward $TARGET" >> "$LOG"

# Wait for quota up front (bounded) rather than burning a full pass finding
# out it's still exhausted. Firebase Spark daily quotas reset once per
# ~24h; 80 * 15min = 20h of patience so a single launch survives overnight
# through the actual reset instead of giving up a few hours early.
for w in $(seq 1 80); do
  ok=$(python - <<'EOF'
from google.cloud import firestore
from google.oauth2 import service_account
try:
    creds = service_account.Credentials.from_service_account_file("android/tools/serviceAccount.json")
    db = firestore.Client(credentials=creds, project="college-reality")
    db.collection("colleges").document("aishe_53").get()
    print("OK")
except Exception:
    print("BLOCKED")
EOF
)
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') pre-flight quota check: $ok" >> "$LOG"
  if [ "$ok" = "OK" ]; then break; fi
  powershell -Command "Start-Sleep -Seconds $QUOTA_RETRY_SLEEP" > /dev/null 2>&1
done

for i in $(seq 1 $MAX_PASSES); do
  current=$(python -c "
import json
try:
    d=json.load(open('tools/data/image_enrichment_checkpoint.json'))
    print(sum(1 for v in d['attempted'].values() if v.get('status')=='enriched'))
except Exception:
    print(0)
")
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') pass $i starting, current enriched=$current" >> "$LOG"

  if [ "$current" -ge "$TARGET" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') target reached ($current >= $TARGET), stopping." >> "$LOG"
    break
  fi

  python tools/enrich_college_images_web_search.py \
    --target "$TARGET" --candidate-cap 30000 --sub-cap 2500 --workers 14 \
    --checkpoint-every 15 --report >> "$LOG" 2>&1
  rc=$?

  new=$(python -c "
import json
try:
    d=json.load(open('tools/data/image_enrichment_checkpoint.json'))
    print(sum(1 for v in d['attempted'].values() if v.get('status')=='enriched'))
except Exception:
    print(0)
")
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') pass $i finished rc=$rc, enriched now=$new" >> "$LOG"

  if [ "$new" -ge "$TARGET" ]; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') target reached ($new >= $TARGET), stopping." >> "$LOG"
    break
  fi

  if [ "$new" -eq "$current" ]; then
    # No progress this pass — likely quota exhaustion or pool exhaustion.
    # Pause longer before retrying so the next pass has a real chance.
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') no progress this pass, pausing ${QUOTA_RETRY_SLEEP}s" >> "$LOG"
    powershell -Command "Start-Sleep -Seconds $QUOTA_RETRY_SLEEP" > /dev/null 2>&1
  else
    powershell -Command "Start-Sleep -Seconds $PASS_SLEEP" > /dev/null 2>&1
  fi
done

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') continuous run loop exited" >> "$LOG"
