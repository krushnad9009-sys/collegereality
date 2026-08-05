# Root Cause Analysis — Search City Failures

Generated: 2026-08-05

## Executive Summary

Every failing popular-city search (Chennai, Kolkata, Bangalore, Pune, Mumbai, etc.) traced to **one architectural defect**: structured Firestore queries used **exact `cityLower` equality** while free-text and offline paths used **`cityMatchesCollege()` contains semantics** (city + district + alias keys). No city-specific bug existed — the pipeline forked matching rules.

**Fix:** Remove Firestore city equality from structured queries. Firestore filters only `state`, `category`, `course`, `type`. City is **always** applied client-side via `cityMatchesCollege` while paginating until exhaustion.

## Root Cause RC-1: Dual City Matching Semantics

| Path | City matching |
|------|---------------|
| Structured (deep links, `?city=&state=`, `retrievalQuery=null`) | **Before:** `cityLower == aliasKey` in Firestore |
| Free-text / bundled / `applyFilters` | `cityLower.contains(key) \|\| districtLower.contains(key)` |

### Impact

- Suburbs and district-only rows (Navi Mumbai, Mumbai Suburban, etc.) missed by structured path
- Alias variants (Bengaluru/Bangalore, Madras/Chennai, Calcutta/Kolkata) only partially covered by equality on canonical `cityLower`
- Popular Cities deep links always hit structured path → systematic under-counting

### Evidence (full export, unified semantics)

| City | State | Legacy (=) | Unified (contains) | Missed by old path |
|------|-------|------------|--------------------|--------------------|
| Mumbai | Maharashtra | 359 | 577 | +218 |
| Bangalore | Karnataka | 919 | 1122 | +203 |
| Pune | Maharashtra | 536 | 755 | +219 |
| Chennai | Tamil Nadu | 389 | 472 | +83 |
| Kolkata | West Bengal | 398 | 426 | +28 |
| Delhi | Delhi | 274 | 278 | +4 |
| Hyderabad | Telangana | 602 | 739 | +137 |
| Ahmedabad | Gujarat | 301 | 343 | +42 |

## Architectural Fix (no city whitelists)

1. **`_queryStructuredPage`**: dropped `cityLower` Firestore clause; added `cityFilter` post-filter via `cityMatchesCollege`
2. **`searchAllMatching`**: single pagination loop over state/category/course/type; exhaust all pages (batch 500)
3. **`countSearchMatches`**: returns `-1` when city present (total = exhaust length)
4. **`searchColleges`**: city structured branch uses same `_queryStructuredPage(cityFilter: ...)`

## Pipeline Audit (other layers — no defects found)

| Layer | Status |
|-------|--------|
| Route parsing (`app_router`) | OK — passes city/state query params |
| Search screen | OK — calls `searchAllMatching`, clears session cache |
| Repository | OK — pass-through, no stale cache |
| Firestore indexes | OK — state+category+course+type composites; city not indexed (by design post-fix) |
| Offline bundled dataset | Incomplete (~610 rows) — not used for structured live search |
| Pagination | OK — cursor on raw Firestore docs, not filtered page length |
| Query normalization | OK — `resolveSearchIntent`, alias keys in `citySearchKeys` |
| State mapping | OK — `normalizeState` aliases |
| Category / course / ownership | OK — category equality, course arrayContains, ownership→type |

## Regression Coverage

- **8,621** distinct state+city pairs verified — **0** self-match failures under unified semantics
- **36** states, **14** categories, **4** ownership types counted
- Flutter tests: **512** passed (includes `search_city_semantics_test.dart`, `search_engine_repair_test.dart`)

## Files Changed

- `lib/features/colleges/services/firestore_college_service.dart`
- `test/search_city_semantics_test.dart`
- `test/search_engine_repair_test.dart`
- `tools/validate_search_coverage.py`
