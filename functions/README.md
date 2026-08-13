# Cloud Functions — paid consultations backend

Trusted server-side logic for "Talk to a Verified Student/Alumni". This is
the only thing in the codebase allowed to mark a payment successful, split
platform fee vs. guide earnings, issue refunds, or mint a real-time call
token. The Flutter app and firestore.rules deliberately cannot do any of
that themselves — see the top-level plan discussion for why.

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
```

- Razorpay keys: Dashboard > Settings > API Keys (use **test mode** keys
  while developing — Razorpay test mode processes no real money).
- Razorpay webhook secret: Dashboard > Settings > Webhooks > Add New
  Webhook, pointed at `https://<region>-<project>.cloudfunctions.net/razorpayWebhook`
  after first deploy, subscribed to `payment.captured` and `payment.failed`.
  The secret you set there must match `RAZORPAY_WEBHOOK_SECRET` exactly.
- Agora: create a project at console.agora.io, enable "App Certificate"
  (primary certificate), copy App ID + App Certificate.

Without these five secrets configured, every callable in this directory
throws rather than doing anything with a placeholder/fake value — there is
no fallback that pretends to succeed.

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
