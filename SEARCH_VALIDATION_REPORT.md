# Search Validation Report

Generated: 2026-08-05

## Gate Status: PASS

All validation gates passed against `tools/data/firestore/india_colleges_firestore_full.json` (47,139 active records).

## Mandatory Category Counts (unified semantics)

| Category | Count | Prior audit target | Status |
|----------|-------|-------------------|--------|
| Engineering | 4414 | 4253 | PASS (≥ target) |
| Medical | 1386 | 1359 | PASS |
| Nursing | 3179 | 3016 | PASS |

## Popular City Deep Links (PopularCitiesSection)

| City | State | Result count (unified) | Status |
|------|-------|------------------------|--------|
| Mumbai | Maharashtra | 577 | PASS |
| Delhi | Delhi | 278 | PASS |
| Bangalore | Karnataka | 1122 | PASS |
| Pune | Maharashtra | 755 | PASS |
| Hyderabad | Telangana | 739 | PASS |
| Chennai | Tamil Nadu | 472 | PASS |
| Kolkata | West Bengal | 426 | PASS |
| Ahmedabad | Gujarat | 343 | PASS |

## Full City Coverage

- Distinct state+city pairs tested: **8,621**
- City self-match failures: **0**
- States with searchable records: **36**

## Unit Tests

```
flutter test test/search_city_semantics_test.dart test/search_engine_repair_test.dart
→ 22 tests passed

flutter test (full suite)
→ 512 tests passed
```

## Evidence

- `tools/data/search_validation_evidence.json`
- `SEARCH_COVERAGE_REPORT.md`
