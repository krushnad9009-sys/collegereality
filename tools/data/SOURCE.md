# Maharashtra AISHE — Data Source & License

## Primary source

| Field | Value |
|---|---|
| **Dataset** | Institutions (AISHE Survey) |
| **Publisher** | Ministry of Education, Government of India |
| **Portal** | [data.gov.in/catalog/institutions-aishe-survey](https://www.data.gov.in/catalog/institutions-aishe-survey) |
| **Policy** | National Data Sharing and Accessibility Policy (NDSAP) |

## One-command pipeline

```powershell
pip install firebase-admin requests
# Place Firebase service account at tools/serviceAccount.json (see serviceAccount.example.json)
python tools/run_maharashtra_firestore_import.py
```

This will:
1. Auto-download AISHE CSV (open-government mirror)
2. Clean & categorize 5,378 Maharashtra colleges
3. Generate CSV + Firestore JSON
4. Import all docs to `college-reality` Firestore
5. Verify document count
6. Repair missing `searchTokens` for search

## Categories mapped

Engineering, MBA, Law, Pharmacy, Polytechnic, Arts, Commerce, Science, Medical, Nursing, Agriculture, Architecture, Fashion, General

## Outputs

| File | Purpose |
|---|---|
| `tools/data/processed/maharashtra_colleges_clean.csv` | Cleaned CSV |
| `tools/data/firestore/maharashtra_colleges_firestore.json` | Full Firestore import (gitignored, ~14MB) |
| `assets/data/maharashtra_colleges_seed.json` | 300-college dev bootstrap |

## Manual import

```powershell
python tools/import_colleges_bulk.py `
  --input tools/data/firestore/maharashtra_colleges_firestore.json `
  --project college-reality `
  --credentials tools/serviceAccount.json `
  --verify-state Maharashtra
```

## Deploy indexes (required for search)

```powershell
firebase deploy --only firestore:indexes --project college-reality
```
