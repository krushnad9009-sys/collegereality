# Bug Fix Report — Product Stabilization

Date: 2026-08-03  
Branch: main  
Mode: Product Stabilization (functional fixes only — no UI redesign)

## Critical fixes shipped

### P0 — Search / filters
| ID | Issue | Fix |
|----|-------|-----|
| S1 | Nursing (and other browse categories) crashed Category dropdown when deep-linked | Full `CollegeConstants.collegeCategories`; clamp unknown values before dropdown bind |
| S2 | Duplicate course/state dropdown values could assert | `dedupePreserveOrder` + `clampToAllowed` |
| S3 | Quota/offline cache returned unfiltered results for filtered searches | Prefer filtered `CollegeBundledDataSource.search` whenever filters are present |
| S4 | State filters empty for misspelled seed data (Chhatisgarh/Uttrakhand) | Alias map in `CollegeSearchUtils.normalizeState`; Firestore uses `stateLower` |

### P1 — Home hierarchy
| ID | Issue | Fix |
|----|-------|-----|
| H1 | "Browse by Type" was actually categories | Renamed to **Browse by Category** |
| H2 | "+ Add My College" competed with search/featured | Moved below Featured Colleges as OutlinedButton |

### P1 — Auth / navigation / empty & error states
| ID | Issue | Fix |
|----|-------|-----|
| A1 | Admin redirect threw when `isStaffProvider` failed | try/catch → treat as non-staff / home |
| A2 | Forgot password `setState` after dispose | Guard with `mounted` |
| A3 | Guest write-review lost destination after login | `RouteNames.loginWithReturn` / `safeReturnPath`; router + login honor `from` |
| A4 | Admin login left session on staff-check failure | Always sign out when not staff or on failure |
| R1 | Write-review media upload force-unwrapped null user | Null-safe login redirect + catch on photo/video upload |
| R2 | Write-review / reviews tab poor error UI | `AsyncErrorView.fromError` with retry |
| P1 | Profile guest dead-end without CTA | Log in button |
| D1 | College detail null college had no recovery | `AsyncEmptyView` + Back to search |
| T1 | Async state widgets broke tests (GoogleFonts ExtraBold) | Use `AppFonts.plusJakarta` (test-safe fallback) |

## Regression tests added
- `test/search_filter_stabilization_test.dart` — Nursing deep link, category parity, state aliases, dedupe/clamp
- `test/auth_return_path_test.dart` — safe return path allow/deny + loginWithReturn

## Remaining non-blocking follow-ups
- Pagination `hasMore` / cursor after client re-rank can still be misleading
- Token search does not paginate
- Index-miss Firestore fallback still samples name prefix (empty risk for rare filters)
- Broader admin CRUD / Firebase write path device QA
- Live Firestore composite index validation for `stateLower`

## Verification
See `TEST_REPORT.md` and `PRODUCTION_CHECKLIST.md`.