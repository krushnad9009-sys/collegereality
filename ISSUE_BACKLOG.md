# Production Issue Backlog — College Reality

Last updated: 2026-08-04

## Status legend
- [x] Fixed in Batch 1 (this commit)
- [ ] Open

## P0 — Crash / wrong data / broken core
- [x] SF-P0-1 City fallback dropped sibling filters
- [x] SF-P0-2 Index-miss fallback sampled 24 name docs (now bundled filtered search)
- [x] SF-P0-3 hasMore/cursor after re-rank (cursor from page window; hasMore from fetch window)
- [x] UX-P0-1 Featured ≈ Trending (trending now sorts by reviewCount)
- [x] UX-P0-2 Guest Helpful/Report silent no-ops (login with return)
- [x] WIP-P0-1 Super Admin UTF-16 WIP files + home wiring compile

## P1 — Broken functionality
- [x] SF-P1-3/4 Search cache keyed by filter signature; bundled load-more stops
- [x] SF-P1-5 Deep-link didUpdateWidget resets filters
- [x] SF-P1-6 Bangalore/Bengaluru aliases
- [x] Course fuzzy match (B.Tech ≈ BTech)
- [ ] SF-P1-1 Token text search pagination
- [ ] SF-P1-2 City+university under-fetch (partially mitigated via wider fetch)
- [ ] REV-P1 My Reviews edit CTA + Reviews tab sort/filter
- [ ] NAV-P1 College detail AppBar overflow on narrow screens
- [ ] ADM-P1 Wire PDF export into Export screen; ads CTA launch URL

## P2–P4 — Open
- Duplicate featured providers / dead autocomplete
- Ratings vs Reviews tab overlap
- Add My College section hierarchy polish
- Semantics / GoogleFonts direct usage
- Taxonomy editing in Super Admin settings
- Admin shell Roles/Ads/Audit for in-app /admin

## Quality gates (Batch 1)
- flutter analyze: PASS
- flutter test: PASS (466)
- flutter build apk --release: pending
- flutter build web --release: pending