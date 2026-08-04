# Production Issue Backlog - College Reality

Last updated: 2026-08-04 (Critical Product QA)

## Status legend
- [x] Fixed
- [ ] Open

## P0 - Crash / wrong data / broken core
- [x] SF-P0-1 City fallback dropped sibling filters
- [x] SF-P0-2 Index-miss fallback bundled filtered search
- [x] SF-P0-3 hasMore/cursor after re-rank
- [x] UX-P0-1 Featured vs Trending sort split
- [x] UX-P0-2 Guest Helpful/Report login with return
- [x] SF-P0-A Course exact arrayContains empty -> fuzzy fallback
- [x] SF-P0-B Delhi / New Delhi aliases + merge
- [x] SF-P0-C Bundled cursor pagination + load-more dedupe
- [x] SF-P0-D Local search cache only stores unfiltered pages
- [x] AUTH-P0 Display-name / signup preserves from return path
- [x] ADM-P0 Admin college edit state/type dropdown clamp
- [x] ADM-P0 Admission predictor exam dropdown uses stable id

## P1 - Broken functionality
- [x] SF-P1-1 Token text search pagination hasMore
- [x] SF-P1-3 courseMatches BA not MBA false positives
- [x] SF-P1-4 Featured session cache limit race
- [x] SF-P1-5 Offline trending sorts by reviewCount
- [x] SF-P1-7 Load more ID dedupe
- [x] UX-P1-A Home promo ad CTA launches URL
- [x] UX-P1 Guest Ask Student / Save / Bookmark / Report auth return
- [x] HOME-P1 Add My College after Reviews; remove Top Branches duplicate
- [x] REV-P1 My Reviews edit CTA
- [x] STATE-P1 Placements/Questions tab AsyncErrorView + retry
- [ ] SF-P1-2 City+university under-fetch (partially mitigated)
- [ ] NAV-P1 College detail AppBar overflow on narrow screens
- [ ] ADM-P1 Wire PDF export into Export screen

## P2-P4 - Open
- Ratings vs Reviews tab overlap
- Taxonomy editing in Super Admin settings
- Admin shell Roles/Ads/Audit for in-app /admin

## Quality gates (Critical QA batch)
- flutter analyze: PASS
- flutter test: PASS (477)
- flutter build apk --release: PASS (71.7MB)
- flutter build web --release: PASS