# Bug Fix Report — Product Stabilization Batch 1

Date: 2026-08-04  
Branch: main  
Mode: Product Stabilization (functional fixes; no UI redesign)

## Critical fixes

### Search / filters
| ID | Issue | Fix |
|----|-------|-----|
| S1 | Nursing/browse category deep-link crashed Category dropdown | Full `collegeCategories` + clamp before dropdown bind |
| S2 | Duplicate course/state dropdown values could assert | `dedupePreserveOrder` + `clampToAllowed` |
| S3 | Quota cache returned unfiltered results for filtered searches | Filtered path uses bundled search; cache keyed by filter signature |
| S4 | State filters empty for misspelled seed data | `normalizeState` aliases; Firestore `stateLower` |
| S5 | City fallback ignored state/course/category | Full `_applyClientFilters` after city fallback |
| S6 | Index-miss fallback near-empty for filters | Fallback uses `CollegeBundledDataSource.search` |
| S7 | Pagination cursor/hasMore misleading after re-rank | Cursor from pre-rank page window; hasMore from fetch fullness |
| S8 | Bangalore deep link missed Bengaluru rows | City alias keys + city fallback variants |
| S9 | Course dropdown exact match too strict | `courseMatches` normalizes punctuation/case |
| S10 | Deep-link filter updates left stale UI state | `didUpdateWidget` reapplies initials and re-searches |

### Home / auth / reviews / details
| ID | Issue | Fix |
|----|-------|-----|
| H1 | Browse by Type mislabeled | Renamed Browse by Category |
| H2 | Add My College competed with hero | Moved below Featured |
| H3 | Featured/Trending identical | Trending sorted by review count |
| A1 | Admin staff-check redirect throw | try/catch in router |
| A2 | Forgot password setState after dispose | mounted guard |
| A3 | Guest write-review lost return URL | `loginWithReturn` / `safeReturnPath` |
| A4 | Admin login left session on staff-check failure | signOut when not staff / on failure |
| R1 | Write-review media upload null user crash | null-safe redirect + catch |
| R2 | Write-review / reviews tab poor error UI | AsyncErrorView with retry |
| R3 | Guest helpful/report no feedback | redirect to login with return path |
| P1 | Profile guest dead-end | Log in CTA |
| D1 | Null college detail no recovery | AsyncEmptyView + Back to search |

## Super Admin extensions
- Roles and Permissions (`/panel/roles`)
- Ads and Promotions CRUD (`/panel/ads`)
- Audit Logs (`/panel/audit-logs`)
- Student Life route wired
- College Featured + Active/Published toggles
- Platform announcement/banner/ads consumed on Home
- Admin action logger on user + review moderation

## Regression tests
- `test/search_filter_stabilization_test.dart`
- `test/auth_return_path_test.dart`
- `test/search_p0_regression_test.dart`
