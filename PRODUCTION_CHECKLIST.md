# Production Checklist — College Reality

## Search & discovery
- [x] Search by college name
- [x] Search by city (deep link + field)
- [x] Search by university field
- [x] Search by course dropdown
- [x] Category filters include Nursing + browse parity
- [x] State filters with spelling aliases
- [x] Duplicate dropdown values guarded
- [x] Empty / error / loading search states present
- [ ] Pagination correctness under heavy client ranking (follow-up)
- [ ] Live Firestore index validation for `stateLower` composites (ops)

## Home
- [x] Featured Colleges above secondary CTAs
- [x] Add My College placement (after Featured)
- [x] Top Branches = courses; Browse by Category = categories (no label collision)
- [x] Popular Cities deep links

## Navigation & auth
- [x] Admin staff check failures do not crash router
- [x] Forgot password mounted guard
- [x] Profile guest login CTA
- [x] Post-login return to write-review (`from` query)
- [x] Protected routes redirect to login with return path

## College details & reviews
- [x] Null college empty state with recovery
- [x] Review media upload null-user safe
- [x] Reviews tab / write-review error retry

## Admin
- [x] Non-staff redirected home without throw
- [x] Admin login signs out non-staff / failed staff check
- [ ] Full admin CRUD device QA (follow-up)

## Quality gates
- [x] `flutter analyze` clean
- [x] `flutter test` all green (463)
- [x] `flutter build apk --release` success
- [x] Reports committed
- [ ] Pushed to main