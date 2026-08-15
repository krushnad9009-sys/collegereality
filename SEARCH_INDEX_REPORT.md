# SEARCH_INDEX_REPORT — College Reality

Generated: 2026-08-05T04:51:54.981751+00:00
Audit mode: **read-only**

## How search indexing works in production

Production search does **not** use SQLite or a separate search engine collection.

1. **Primary:** Firestore collection `colleges` on project `college-reality`
2. **In-document index fields:** `searchTokens` (array), `nameLower`, `cityLower`, `stateLower`, `universityLower`, `districtLower`, `courses`, `category`, `type`
3. **Fallback when quota/index fails:** bundled JSON via `CollegeBundledDataSource` (**610** colleges)

## Index size vs database size

| Metric | Value | Evidence |
|---|---:|---|
| Live DB documents | **45,020** | Firestore aggregation count |
| Docs with `searchTokens` (export full) | **47,139 / 47,139** | JSON field scan |
| Docs with `searchTokens` (live sample) | **5,000 / 5,000** | Stream sample |
| Sample missing/empty token rate | **0.0%** | Live sample |
| Bundled docs missing tokens | **110 / 610** | Seed analysis |

**Conclusion:** For documents that exist in Firestore, `searchTokens` coverage looks complete in the audited sample/export. The larger production gap is **missing documents** and **missing searchable fields** (university/ownership), not a separate token-index lag.

## Field-by-field search readiness

| Field | Production readiness | Evidence |
|---|---|---|
| College Name (`name` / `nameLower`) | PASS | 100% present in export + live sample |
| City (`city` / `cityLower`) | PASS | 100% present; live Pune=533, Mumbai=353 |
| State (`state` / `stateLower`) | PASS | 100% present in export + sample |
| University (`universityName` / `universityLower`) | **FAIL** | **0%** present in export (47,139 missing) and live sample (5,000 missing) |
| Course (`courses`) | PASS (array present) | 100% present in export; AISHE pipeline values are often category-derived |
| Category (`category`) | PASS | 100% present; live counts queried |
| Ownership (`ownership`) | **FAIL** | **0%** present; only `type` (government/private/...) is populated |

## Colleges that never appear in search

1. **Not in live DB:** 47,139 - 45,020 = **2,119** expected colleges absent from production Firestore (`import_final_report.missingColleges`).
2. **University queries:** essentially all colleges are invisible to true university-field search because university fields are empty.
3. **Ownership queries:** no ownership data; filtering by ownership field cannot work.
4. **Quota/offline path:** only 610 bundled colleges are searchable; 110 of those lack `searchTokens`.

### Bundled colleges missing searchTokens (sample)

- id=`college_001` name=`Global Mumbai Institute of Technology` city=`Mumbai`
- id=`college_002` name=`Progressive Pune College of Pharmacy` city=`Pune`
- id=`college_003` name=`United Nagpur College of Engineering` city=`Nagpur`
- id=`college_004` name=`Central Nashik Polytechnic` city=`Nashik`
- id=`college_005` name=`Heritage Aurangabad Academy of Science` city=`Aurangabad`
- id=`college_006` name=`Global Bangalore University` city=`Bangalore`
- id=`college_007` name=`Modern Mysore School of Business` city=`Mysore`
- id=`college_008` name=`Progressive Mangalore Institute of Technology` city=`Mangalore`

## Live targeted search counts (Firestore)

| Query | Count |
| --- | --- |
| cityLower_pune | 533 |
| cityLower_mumbai | 353 |
| city_Pune | 533 |
| city_Mumbai | 353 |
| category_Engineering | 4253 |
| category_Medical | 1359 |
| category_MBA | 2196 |
| category_Pharmacy | 1035 |
| category_Nursing | 3016 |
| category_Law | 720 |
| category_Commerce | 1530 |
| category_Arts | 1379 |
| isActive_true | 45020 |
| isActive_false | 0 |

## Duplicate pollution risk for search

Export payload contains thousands of near-duplicate colleges (same name/city/state, different IDs).

- Duplicate ID groups: **3882**
- Name+city+state duplicate groups: **4025**

Example: `new delhi institute of management|new delhi|delhi` -> IDs: `aishe_32887`, `aishe_78`, `aishe_78_new-delhi-institute-of-management-new-delhi`

## Meta vs live search facets

`_meta/collegeDirectory` stores export-sized category/state totals (**sum 47,139**) while live DB is **45,020**. Facet counts from meta overstate availability vs actual searchable docs.

## PASS / FAIL (search index)

# FAIL

Must-fix before production:
1. Finish importing the missing **2,119** colleges (or correct product claims to **45,020**).
2. Rebuild `_meta/collegeDirectory` counts from **live** aggregations.
3. Populate `universityName` / `universityLower` (or disable university search).
4. Populate `ownership` (or map ownership UX solely to `type` and document it).
5. Do not treat bundled 610-college fallback as production search coverage.
6. Deduplicate AISHE export before any re-import (4k+ duplicate groups).
