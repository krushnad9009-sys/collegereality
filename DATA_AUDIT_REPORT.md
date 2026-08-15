# DATA_AUDIT_REPORT — College Reality

Generated: 2026-08-05T04:51:54.981751+00:00
Audit mode: **read-only** (no application code or database writes)
Production project: `college-reality`
Primary collection: `colleges`

## Executive verdict

# FAIL

**Does the application truly contain 45,020 colleges?**
**YES — live Firestore currently contains exactly 45,020 documents** in `colleges` (aggregation query).

**Does it contain 47,000+ colleges?**
**NO.** Live count is 45,020. The AISHE/export payload has 47,139 rows; production is short by 2,119. UI copy saying "47,000+" is not backed by the live database.

---

## Evidence sources used

| Source | Role | Query / method |
|---|---|---|
| Live Firestore `college-reality` / `colleges` | Production DB | `collection.count()`, field equality `.count()`, stream sample `limit(5000)`, `_meta/collegeDirectory` get |
| `tools/data/firestore/india_colleges_firestore_full.json` | Full import export payload | Loaded all **47,139** JSON records |
| `assets/data/*.json` | Offline/quota fallback | Merged exactly as `CollegeBundledDataSource.loadAll()` |
| `tools/data/import_final_report.json` | Prior import snapshot (2026-07-24) | Read-only |

Raw machine evidence: `tools/data/audit_evidence.json`

---

## 1. Total records

| Dataset | Total records | Evidence |
|---|---:|---|
| **Live Firestore `colleges`** | **45,020** | `db.collection('colleges').count()` -> `45020` |
| `_meta/collegeDirectory.totalColleges` | 45,020 | Meta doc field |
| Import export JSON | 47,139 | `len(india_colleges_firestore_full.json)` |
| Prior import report `totalFirestoreDocuments` | 45,020 | `import_final_report.json` |
| Bundled `loadAll()` unique | 610 | Merged seed assets |

## 2. Total unique colleges

| Dataset | Unique non-empty IDs | Notes |
|---|---:|---|
| Live Firestore | 45,020 | Document IDs unique; 5,000-doc sample had 0 duplicate IDs |
| Export JSON | **43,118** | Among 47,139 rows (4,021 duplicate-ID extras) |
| Bundled merge | 610 | |

## 3. Duplicate colleges (name + city + state)

### Export JSON
- Duplicate groups: **4,025**
- Extra duplicate rows: **4,028**

### Sample duplicate groups (export)

**Key:** `new delhi institute of management|new delhi|delhi` (count=3)
- id=`aishe_32887` name=`New Delhi Institute Of Management` city=`New Delhi` state=`Delhi`
- id=`aishe_78` name=`NEW DELHI INSTITUTE OF MANAGEMENT` city=`New Delhi` state=`Delhi`
- id=`aishe_78_new-delhi-institute-of-management-new-delhi` name=`NEW DELHI INSTITUTE OF MANAGEMENT` city=`New Delhi` state=`Delhi`

**Key:** `vijaya engineering college|khammam|telangana` (count=3)
- id=`aishe_19820` name=`Vijaya Engineering College` city=`Khammam` state=`Telangana`
- id=`aishe_15360` name=`VIJAYA ENGINEERING COLLEGE` city=`Khammam` state=`Telangana`
- id=`aishe_15360_vijaya-engineering-college-khammam` name=`VIJAYA ENGINEERING COLLEGE` city=`Khammam` state=`Telangana`

**Key:** `indur institute of engineering & technology|siddipet|telangana` (count=3)
- id=`aishe_19929` name=`Indur Institute Of Engineering & Technology` city=`Siddipet` state=`Telangana`
- id=`aishe_575` name=`INDUR INSTITUTE OF ENGINEERING & TECHNOLOGY` city=`Siddipet` state=`Telangana`
- id=`aishe_575_indur-institute-of-engineering-technology-siddipet` name=`INDUR INSTITUTE OF ENGINEERING & TECHNOLOGY` city=`Siddipet` state=`Telangana`


### Live sample (5,000 docs)
- Duplicate ID groups in sample: **0**

## 4. Duplicate IDs

### Export JSON
- Duplicate ID groups: **3882**
- Extra docs from duplicate IDs: **4021**
- Top duplicate IDs: `[{'id': 'aishe_535', 'count': 3}, {'id': 'aishe_519', 'count': 3}, {'id': 'aishe_613', 'count': 3}, {'id': 'aishe_506', 'count': 3}, {'id': 'aishe_659', 'count': 3}]`

### Live Firestore
- Document IDs are unique; live total docs = 45,020 unique IDs.

## 5. Colleges grouped by State

### Live meta `stateCounts` (WARNING: sums to export 47,139, not live 45,020)

| State | Meta count |
| --- | --- |
| Uttar Pradesh | 6484 |
| Maharashtra | 6167 |
| Karnataka | 4843 |
| Tamil Nadu | 3775 |
| Andhra Pradesh | 3379 |
| Rajasthan | 2713 |
| Gujarat | 2653 |
| Madhya Pradesh | 2634 |
| Telangana | 2289 |
| Kerala | 1736 |
| West Bengal | 1624 |
| Odisha | 1591 |
| Punjab | 1296 |
| Haryana | 990 |
| Chhatisgarh | 853 |
| Bihar | 806 |
| Uttrakhand | 578 |
| Assam | 569 |
| Himachal Pradesh | 469 |
| Jammu And Kashmir | 381 |
| Jharkhand | 356 |
| Delhi | 303 |
| Puducherry | 105 |
| Nagaland | 87 |
| Goa | 75 |
| Manipur | 70 |
| Tripura | 68 |
| Meghalaya | 63 |
| Mizoram | 54 |
| Chandigarh | 39 |
| Sikkim | 36 |
| Arunachal Pradesh | 24 |
| Daman & Diu | 9 |
| Dadra & Nagar Haveli | 9 |
| Andaman & Nicobar Islands | 8 |
| Lakshadweep | 3 |

Meta stateCounts sum = **47139** (mismatch vs live 45,020).

### Export JSON top states

| State | Export count |
| --- | --- |
| Uttar Pradesh | 6484 |
| Maharashtra | 6167 |
| Karnataka | 4843 |
| Tamil Nadu | 3775 |
| Andhra Pradesh | 3379 |
| Rajasthan | 2713 |
| Gujarat | 2653 |
| Madhya Pradesh | 2634 |
| Telangana | 2289 |
| Kerala | 1736 |
| West Bengal | 1624 |
| Odisha | 1591 |
| Punjab | 1296 |
| Haryana | 990 |
| Chhatisgarh | 853 |

## 6-7. Colleges by City / Top 50 cities

Source: export JSON full scan (47,139 rows). Live city counts for Pune/Mumbai also queried directly.

### Top 50 cities (export)

| City | Count |
| --- | --- |
| Bangalore | 863 |
| Hyderabad | 604 |
| Pune | 536 |
| Jaipur | 426 |
| Kolkata | 397 |
| Chennai | 389 |
| Mumbai | 359 |
| Bhopal | 346 |
| Allahabad | 329 |
| Nagpur | 320 |
| Ahmedabad | 301 |
| Lucknow | 301 |
| Coimbatore | 257 |
| Indore | 249 |
| Bhubaneswar | 223 |
| Gulbarga | 219 |
| Meerut | 215 |
| Aurangabad | 205 |
| Visakhapatnam | 194 |
| Azamgarh | 193 |
| Varanasi | 190 |
| Ghazipur | 188 |
| Jaunpur | 184 |
| Mangalore | 175 |
| Gwalior | 166 |
| Mysore | 160 |
| Nashik | 158 |
| Agra | 154 |
| Gorakhpur | 154 |
| Jabalpur | 153 |
| New Delhi | 151 |
| Rajkot | 149 |
| Guntur | 144 |
| Raipur | 138 |
| Sikar | 132 |
| Guwahati | 129 |
| Nellore | 128 |
| Salem | 128 |
| Madurai | 127 |
| Surat | 126 |
| Delhi | 125 |
| Bidar | 125 |
| Tumkur | 125 |
| Mau | 121 |
| Faizabad | 121 |
| Dehradun | 121 |
| Kadapa | 120 |
| Patna | 119 |
| Pratapgarh | 113 |
| Ghaziabad | 112 |

## 8. Pune college count

| Method | Count | Evidence |
|---|---:|---|
| Live `cityLower == "pune"` | **533** | Firestore aggregation |
| Live `city == "Pune"` | **533** | Firestore aggregation |
| Export city match Pune/Poona | **567** | Full JSON scan |
| Bundled fallback | 18 | Seed merge |

## 9. Mumbai college count

| Method | Count | Evidence |
|---|---:|---|
| Live `cityLower == "mumbai"` | **353** | Firestore aggregation |
| Live `city == "Mumbai"` | **353** | Firestore aggregation |
| Export city match Mumbai/Bombay | **501** | Full JSON scan |
| Bundled fallback | 13 | Seed merge |

## 10-12. Category counts

| Category | Live Firestore `.count()` | Meta `categoryCounts` | Export JSON |
|---|---:|---:|---:|
| Engineering | 4253 | 4414 | 4414 |
| Medical | 1359 | 1386 | 1386 |
| MBA | 2196 | 2282 | 2282 |
| Pharmacy | 1035 | 1052 | 1052 |
| Nursing | 3016 | 3179 | 3179 |
| Law | 720 | 731 | 731 |
| Commerce | 1530 | 1544 | 1544 |
| Arts | 1379 | 1433 | 1433 |

Meta categoryCounts sum = **47139** (export-sized, not live).

## 13. Missing mandatory fields

Mandatory checked: `id`, `name`, `city`, `state`, `category`, `type`

### Export JSON (47,139)

| Field | Missing count |
|---|---:|
| id | 0 |
| name | 0 |
| city | 0 |
| state | 0 |
| category | 0 |
| type | 0 |

### Live sample (5,000)
Mandatory missing counts are 0 in sample analysis (`tools/data/audit_evidence.json` -> `firestore_live.sample_analysis.missing_mandatory`).

## 14. Invalid records

Export invalid (missing id/name/city/state/category): **0**
Live `isActive==true`: **45020**; `isActive==false`: **0**

## 15. Broken references

- No separate SQL foreign-key store. Production references are Firestore doc IDs.
- **Broken analytics reference:** `_meta/collegeDirectory` category/state maps describe **47,139** expected rows, not the live **45,020** docs.
- University/ownership fields absent -> any feature expecting those fields is broken against production data.
- Offline bundled set (610) is not a reference-complete mirror of production.

## 16-17. Colleges that never appear in search / missing from search index

Search index is in-document `searchTokens` plus field prefixes (`nameLower`, `cityLower`, etc.).

| Check | Result | Evidence |
|---|---|---|
| Export docs missing `searchTokens` | **0 / 47,139** | Full JSON scan |
| Export docs with empty `searchTokens` | **0 / 47,139** | Full JSON scan |
| Live sample missing/empty tokens | **0 / 5,000** | Firestore stream sample |
| Invisible to university search | **All docs** (no university fields) | Coverage below |
| Offline fallback missing tokens | **110 / 610** | Bundled analysis |

Colleges missing from search in practice:
1. The **2,119** colleges never imported to live Firestore.
2. Any college relying on **university** or **ownership** match — fields empty.
3. Under Firestore quota, app falls back to **610** bundled colleges only.

## 18. Search index size versus database size

| Metric | Value |
|---|---:|
| Live DB size | 45,020 docs |
| Live sample with `searchTokens` present | 5,000 / 5,000 (100%) |
| Export with `searchTokens` present | 47,139 / 47,139 (100%) |
| Bundled with `searchTokens` present | 500 / 610 |

No separate search-index collection; searchable coverage ~= docs with populated search fields.

## 19. Searchable field coverage

### Export JSON (full 47,139)

| Field | Present | Missing | Coverage |
| --- | --- | --- | --- |
| name | 47139 | 0 | 100.0% |
| nameLower | 47139 | 0 | 100.0% |
| city | 47139 | 0 | 100.0% |
| cityLower | 47139 | 0 | 100.0% |
| state | 47139 | 0 | 100.0% |
| stateLower | 47139 | 0 | 100.0% |
| universityName | 0 | 47139 | 0.0% |
| universityLower | 0 | 47139 | 0.0% |
| courses | 47139 | 0 | 100.0% |
| category | 47139 | 0 | 100.0% |
| type | 47139 | 0 | 100.0% |
| ownership | 0 | 47139 | 0.0% |
| searchTokens | 47139 | 0 | 100.0% |
| isActive | 47139 | 0 | 100.0% |

### Live sample (5,000)

| Field | Present | Missing | Coverage |
| --- | --- | --- | --- |
| name | 5000 | 0 | 100.0% |
| nameLower | 5000 | 0 | 100.0% |
| city | 5000 | 0 | 100.0% |
| cityLower | 5000 | 0 | 100.0% |
| state | 5000 | 0 | 100.0% |
| stateLower | 5000 | 0 | 100.0% |
| universityName | 0 | 5000 | 0.0% |
| universityLower | 0 | 5000 | 0.0% |
| courses | 5000 | 0 | 100.0% |
| category | 5000 | 0 | 100.0% |
| type | 5000 | 0 | 100.0% |
| ownership | 0 | 5000 | 0.0% |
| searchTokens | 5000 | 0 | 100.0% |
| isActive | 5000 | 0 | 100.0% |

## 20. Every mismatch with evidence

| Mismatch | Expected / claimed | Actual | Evidence |
|---|---|---|---|
| Marketing "47,000+ colleges" | >=47,000 | Live **45,020** | Firestore `count()` |
| Import completeness | 47,139 | Live 45,020 (-2,119) | Live count + `import_final_report.missingColleges=2119` |
| Meta `categoryCounts` | Should mirror live | Sum **47,139** | `_meta/collegeDirectory` |
| Meta vs live Engineering | Same | 4,414 vs **4,253** | Meta vs `where category==Engineering count` |
| Meta vs live Medical | Same | 1,386 vs **1,359** | Same method |
| Export vs unique IDs | 1 row per college | 47,139 rows / 43,118 unique IDs | JSON analysis |
| University searchable | Populated | **0%** present | Export + live sample |
| Ownership searchable | Populated | **0%** present | Export + live sample |
| Offline search = production | Full DB | **610** colleges | Bundled merge |
| Pune export vs live | Similar | Export 567 vs live **533** | JSON scan vs Firestore count |

---

## Issues that MUST be fixed before production (FAIL)

1. Live Firestore document count is **45,020**, not 47,000+. UI/marketing claim of 47,000+ is false for production.
2. Expected AISHE/export set is **47,139**; production is missing **2,119** colleges (live count + prior import report).
3. `_meta/collegeDirectory.categoryCounts` and `stateCounts` sum to **47,139** (export/expected), not live **45,020** — meta analytics are stale/wrong.
4. Live category counts disagree with meta for every checked category (e.g. Engineering live 4,253 vs meta 4,414).
5. `universityName` / `universityLower` are missing on **100%** of export records and **100%** of live 5,000-doc sample — university search cannot match real university fields.
6. `ownership` is missing on **100%** of export records and live sample — ownership search/filter has no data (only `type` exists).
7. Import export JSON contains **3,882** duplicate-ID groups (**4,021** extra docs) and **4,025** name+city+state duplicate groups.
8. Offline/quota bundled fallback contains only **610** unique colleges (not production DB).
9. Bundled fallback is missing `searchTokens` on **110/610** colleges (~18%).

---

## PASS / FAIL

# FAIL

Live database existence and basic mandatory fields for imported docs are largely healthy, but production is **not** complete or search-complete against the claimed 47k AISHE set, meta counts are wrong, university/ownership search data is absent, and offline fallback is not production-scale.
