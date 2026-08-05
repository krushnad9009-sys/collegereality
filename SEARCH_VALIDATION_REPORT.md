# Search Validation Report

**Mode:** Search Engine Repair  
**Generated:** 2026-08-05 (UTC)  
**Live database:** Firestore project college-reality / collection colleges  
**Total documents:** 45,020

## Verdict

**PASS** — Exhaustive pagination over live Firestore matches every audited target exactly.

## Mandatory count verification

| Query | Field | Expected | Aggregation | Exhausted pages | Unique IDs | Result |
|-------|-------|----------|-------------|-----------------|------------|--------|
| Pune | cityLower == pune | 533 | 533 | 533 | 533 | PASS |
| Mumbai | cityLower == mumbai | 353 | 353 | 353 | 353 | PASS |
| Engineering | category == Engineering | 4253 | 4253 | 4253 | 4253 | PASS |
| Medical | category == Medical | 1359 | 1359 | 1359 | 1359 | PASS |
| Nursing | category == Nursing | 3016 | 3016 | 3016 | 3016 | PASS |

Evidence: tools/data/search_validation_evidence.json

## Pipeline fixes

1. Exhaustive live fetch — Search UI calls searchAllMatching, paging Firestore at searchExhaustBatchSize (500) until hasMore is false.
2. No artificial result caps on structured city/category/state/type queries.
3. Stale search cache cleared on each new search (CollegeSessionCache.clearSearch).
4. Live DB preferred — structured city/category/state quota failures rethrow instead of silently returning the tiny bundled set; fromLiveDatabase flags offline fallbacks.
5. Duplicate client filtering removed on structured pages (Firestore equality already constrains city/state/category/course/type). University remains client-side because production universityName coverage is near-zero and falls back to tokens/name.
6. Ownership maps to type in resolveSearchIntent (production ownership empty).
7. City aliases (Pune/Poona, Mumbai/Bombay, etc.) merge via citySearchKeys with id dedupe.
8. Honest pagination cursors — structured pages use Firestore orderBy(nameLower) + startAfterDocument.

## Filter coverage verified (unit + live)

| Case | Status |
|------|--------|
| City search (every matching college) | PASS (live exhaust) |
| Category search | PASS (live exhaust) |
| Category + city + state intent/filters | PASS (unit) |
| University (field + token fallback) | PASS (unit) |
| Ownership / type | PASS (unit) |
| Searchable field intent promotion | PASS (unit) |
| Bundled offline incomplete vs audit | PASS (unit asserts bundled much smaller than live) |

## Automated tests

- test/search_engine_repair_test.dart — regression locks for audit targets, intent, filters, cache clear, offline incompleteness
- Existing search suites retained (search_system_refactor_test.dart, search_p0_regression_test.dart, and related)
- Integration entry: integration_test/core_flows_test.dart

## Test gates

- flutter analyze (colleges/cache/constants): No issues found
- flutter test: 506 passed
- Flow/integration VM suites (test/flows, test/integration): passed
- Device integration_test/core_flows_test.dart -d windows: blocked on this machine (missing Visual Studio Windows toolchain); same flows covered by the VM suite

## Notes

- Free-text name search still uses multi-field merge with batch limits; city/category/state structured paths are exhaustive.
- University-only scans may page the full active set client-side until DB backfills universityName / universityLower.
