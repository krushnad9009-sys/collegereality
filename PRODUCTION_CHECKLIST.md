# Production Checklist — College Reality

## Search and discovery
- [x] Search by college name
- [x] Search by city (deep link + field)
- [x] Search by university field
- [x] Search by course dropdown
- [x] Category filters include Nursing + browse parity
- [x] State filters with spelling aliases
- [x] City aliases (Bangalore/Bengaluru)
- [x] Duplicate dropdown values guarded
- [x] Filtered quota/offline path returns filtered results
- [x] Empty / error / loading search states present
- [x] Deep-link filter updates re-run search
- [ ] Token search pagination (follow-up)
- [ ] Live Firestore index validation for composites (ops)

## Home
- [x] Featured Colleges above secondary CTAs
- [x] Add My College placement (after Featured)
- [x] Top Branches = courses; Browse by Category = categories
- [x] Popular Cities deep links
- [x] Platform announcement / banner / ads strip wired
- [x] Trending ranked separately from Featured

## Navigation and auth
- [x] Admin staff check failures do not crash router
- [x] Forgot password mounted guard
- [x] Profile guest login CTA
- [x] Post-login return to write-review (from query)
- [x] Protected routes redirect to login with return path
- [x] Guest review helpful/report redirect to login

## College details and reviews
- [x] Null college empty state with recovery
- [x] Review media upload null-user safe
- [x] Reviews tab / write-review error retry
- [ ] Review sort/filter UI (follow-up)
- [ ] My Reviews edit entry point (follow-up)

## Admin / Super Admin
- [x] Non-staff redirected home without throw
- [x] Admin login signs out non-staff / failed staff check
- [x] Roles and Permissions screen (/panel/roles)
- [x] Ads and Promotions CRUD (/panel/ads)
- [x] Audit Logs viewer (/panel/audit-logs)
- [x] College Featured + Active/Published toggles
- [x] Admin action logger on user + review moderation
- [ ] Full admin CRUD device QA (follow-up)

## Quality gates
- [x] flutter analyze clean (2 pre-existing warnings in firestore_college_service.dart, unrelated to current work)
- [ ] flutter test all green — 4 pre-existing failures found 2026-09-11, unrelated to the current branch's changes: `admission_models_serialization_test.dart` (ScholarshipModel round-trip), `flows/core_user_flows_test.dart` (2x signup-flow), `widgets/signup_screen_test.dart` (terms checkbox). Reproduce on a clean checkout before assuming this branch caused them.
- [x] flutter build apk --release success (verified 2026-09-11, debug-signed fallback — real Play Store upload still needs the owner's upload keystore, see android/key.properties.example)
- [x] flutter build appbundle --release success (verified 2026-09-11, same signing caveat)
- [x] flutter build web --release success (verified 2026-09-11)
- [x] tool/security-rules-tests passing (69/69 — 64 Firestore + 5 Storage, verified 2026-09-11 incl. new consultation/message rate-limit rules)
- [ ] Reports committed
- [ ] Pushed to main