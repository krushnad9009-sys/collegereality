# Cloud Functions — paid consultations backend + AI chatbot backend

Trusted server-side logic for "Talk to a Verified Student/Alumni" (payment
finalization, fee/earnings split, refunds, call-token minting) and for the
AI Assistant's LLM calls (`aiChatComplete`). Both share one property: the
Flutter app and firestore.rules deliberately cannot do these things
themselves — money movement needs a trusted server, and so does an API key.

## Not deployed automatically

Nobody (including an agent working in this repo) should run
`firebase deploy --only functions` without you explicitly asking for it in
that moment. Nothing here has been deployed.

## Required secrets (Secret Manager, never in source)

```bash
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
firebase functions:secrets:set AGORA_APP_ID
firebase functions:secrets:set AGORA_APP_CERTIFICATE
firebase functions:secrets:set GEMINI_API_KEY
```

- Razorpay keys: Dashboard > Settings > API Keys (use **test mode** keys
  while developing — Razorpay test mode processes no real money).
- Razorpay webhook secret: Dashboard > Settings > Webhooks > Add New
  Webhook, pointed at `https://<region>-<project>.cloudfunctions.net/razorpayWebhook`
  after first deploy, subscribed to `payment.captured` and `payment.failed`.
  The secret you set there must match `RAZORPAY_WEBHOOK_SECRET` exactly.
- Agora: create a project at console.agora.io, enable "App Certificate"
  (primary certificate), copy App ID + App Certificate.
- Gemini API key: create one at https://aistudio.google.com/apikey (a
  Google account, no billing setup required for Gemini Flash-Lite's free
  tier — check current quotas before high-volume launch). Paste it when
  the `firebase functions:secrets:set GEMINI_API_KEY` command above
  prompts you — never into a file in this repo, never into a chat with an
  agent, never into Dart source.

Without these secrets configured, every callable in this directory throws
rather than doing anything with a placeholder/fake value — there is no
fallback that pretends to succeed. `aiChatComplete` specifically falls
back to Flutter's existing database-only answer pipeline when it fails for
any reason (missing key, quota, network) — see
`lib/features/assistant/services/ai_assistant_service.dart` for that path.

## AI chatbot backend (`aiChatComplete`)

Flutter never talks to Gemini directly — see `src/aiChat.js` (the callable
entry point, does only auth + input validation), `src/ai/aiChatService.js`
(orchestrates cache -> per-user daily rate limit -> prompt -> provider),
`src/ai/aiModelProvider.js` (provider abstraction — swap
`src/ai/geminiProvider.js` for another vendor later without touching
anything else), and `src/ai/config.js` (the one place every cost/behaviour
number lives — daily limit, model name, token caps, timeout, cache TTL).

**Request** (all fields except `question` optional):
```json
{
  "question": "How are placements?",
  "mode": "college",              // "college" | "explore"
  "collegeId": "abc123",
  "collegeContext": { "name": "...", "city": "...", "state": "...",
    "category": "...", "crScore": 82, "feesMin": 100000, "feesMax": 200000,
    "avgPackageLpa": 6, "highestPackageLpa": 12, "placementPct": 80,
    "hostelAvailable": true,
    "reviewExcerpts": ["..."], "verifiedAnswerExcerpts": ["..."] },
  "candidateColleges": [ { "id": "..", "name": "..", "city": "..",
    "state": "..", "crScore": 82, "avgPackageLpa": 6, "placementPct": 80,
    "feesMin": 100000 } ],
  "history": [ { "role": "user", "text": "..." },
               { "role": "assistant", "text": "..." } ],
  "filters": { "city": "Pune", "state": "Maharashtra", "course": "B.Tech" }
}
```
The client (Flutter, via the existing `CollegeRepository`/
`AiCollegeDataService`/`AiAssistantService` pipeline) is responsible for
retrieval, filtering, and ranking — this function never queries the
`colleges` collection itself and never receives more than
`AI_CHAT_CONFIG.MAX_CANDIDATE_COLLEGES` (10) colleges at once.

**Response:**
```json
{ "text": "...", "cached": false, "isGeneralAdvice": false }
```

**Authentication:** standard callable-function auth — the Firebase Auth ID
token attached by the Flutter SDK; `request.auth.uid` is required
(`unauthenticated` otherwise).

**Rate limiting:** `aiUsage/{uid}_{utcDate}` doc, incremented in a Firestore
transaction; once a user hits `AI_CHAT_CONFIG.DAILY_REQUEST_LIMIT` (default
40/day) further calls throw `resource-exhausted` until the next UTC day.
Cache hits do not consume quota.

**Caching:** `aiChatCache/{sha256(question+collegeId+mode+filters)}`, TTL
`AI_CHAT_CONFIG.CACHE_TTL_SECONDS` (default 12h). The key never includes a
uid, so it's safe by construction — nothing personal is ever cached.

**Environment variables:** none beyond the `GEMINI_API_KEY` secret above —
everything else is a plain constant in `src/ai/config.js`.

**Deployment:** part of the same `firebase deploy --only functions` as
everything else in this directory — see "Not deployed automatically" above.

## What's real vs. what's still a gap

| Piece | Status |
|---|---|
| Order creation, server-side price re-validation | Implemented |
| Webhook signature verification (HMAC, raw body) | Implemented |
| Idempotent payment finalization (transaction-guarded) | Implemented |
| Platform fee / guide earnings split | Implemented (20%, `consultationLogic.js`) |
| Refund on post-payment cancellation | Implemented (Razorpay refund API) |
| Stale-request expiry / guide-no-answer auto-cancel | Implemented (`onSchedule`) |
| Agora call-token minting (access control + signing) | Implemented |
| **Agora Flutter SDK actually joining a channel with that token** | **NOT implemented** — no `agora_rtc_engine` dependency added to `pubspec.yaml`. Wiring this up needs a real Agora project (see above) and touches native Android/iOS permission config; deliberately left as the next step rather than half-wired against credentials nobody has yet. `CallAccessService.mintCallToken()` on the Flutter side already gets you a valid token — an engine just isn't consuming it yet. |
| Razorpay web checkout | Not implemented — `razorpay_flutter` has no Flutter Web support upstream. Checkout is mobile-only for now; the checkout screen shows a "use the mobile app" message on web instead of a fake payment flow. |
| AI chatbot backend (`aiChatComplete`): cache, rate limit, prompt building, Gemini call, error mapping | Implemented, unit-tested (`test/aiChat.test.js`) |
| AI chatbot backend actually called with a real Gemini API key | **NOT verified live** — no `GEMINI_API_KEY` secret has been set and this directory has never been deployed (see above). Code-reviewed and unit-tested only; the Flutter side falls back to its existing database-only pipeline until this is deployed with a real key. |

## Local testing

```bash
cd functions
npm install
npm test              # pure-logic unit tests, no emulator/credentials needed
npm run serve          # functions + firestore emulators (needs Java, same as tool/security-rules-tests)
```

## Deploy (when you're ready — not run automatically)

```bash
firebase deploy --only functions
```
