#!/usr/bin/env python3
"""Bulk import colleges into Firestore for production (40k+ scale).

Usage:
  pip install firebase-admin
  set GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccount.json
  python tools/import_colleges_bulk.py --input tools/colleges_sample.json

Input JSON: array of college documents matching CollegeModel.toJson() fields.
Batches writes in groups of 450 (Firestore limit).
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def normalize_college(doc: dict) -> dict:
    name = doc.get("name", "").strip()
    city = doc.get("city", "").strip()
    doc.setdefault("nameLower", name.lower())
    doc.setdefault("slug", f"{name}-{city}".lower().replace(" ", "-"))
    doc.setdefault("isActive", True)
    doc.setdefault("reviewCount", 0)
    doc.setdefault("searchTokens", [])
    doc.setdefault("photoUrls", [])
    doc.setdefault("coursesDetailed", [])
    doc.setdefault("hostel", doc.get("hostel") or {"available": False})
    doc.setdefault("accreditation", doc.get("accreditation") or {})
    now = datetime.now(timezone.utc).isoformat()
    doc.setdefault("createdAt", now)
    doc.setdefault("updatedAt", now)
    return doc


def main() -> int:
    parser = argparse.ArgumentParser(description="Import colleges to Firestore")
    parser.add_argument("--input", required=True, help="Path to colleges JSON array")
    parser.add_argument("--project", default=None, help="Firebase project id")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"File not found: {input_path}", file=sys.stderr)
        return 1

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print("Install firebase-admin: pip install firebase-admin", file=sys.stderr)
        return 1

    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {"projectId": args.project} if args.project else None)

    db = firestore.client()
    colleges = json.loads(input_path.read_text(encoding="utf-8"))
    if not isinstance(colleges, list):
        print("Input must be a JSON array of college objects", file=sys.stderr)
        return 1

    batch_size = 450
    total = 0
    for i in range(0, len(colleges), batch_size):
        batch = db.batch()
        chunk = colleges[i : i + batch_size]
        for raw in chunk:
            doc = normalize_college(dict(raw))
            doc_id = doc.pop("id", None) or doc.get("slug") or f"college_{total}"
            batch.set(db.collection("colleges").document(doc_id), doc, merge=True)
            total += 1
        batch.commit()
        print(f"Imported {min(i + batch_size, len(colleges))}/{len(colleges)}")

    db.collection("_meta").document("collegeDirectory").set(
        {
            "totalColleges": total,
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        },
        merge=True,
    )
    print(f"Done. {total} colleges imported.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
