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
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


def build_search_tokens(
    name: str,
    city: str,
    district: str,
    state: str,
    university: str = "",
    courses: list | None = None,
    keywords: list | None = None,
) -> list[str]:
    tokens: set[str] = set()
    corpus = " ".join(
        [name, city, district, state, university, *(courses or []), *(keywords or [])]
    ).lower()
    for word in re.split(r"\W+", corpus):
        if len(word) < 2:
            continue
        tokens.add(word)
        for length in range(3, min(len(word), 12) + 1):
            tokens.add(word[:length])
    return sorted(tokens)[:30]


def normalize_college(doc: dict) -> dict:
    name = doc.get("name", "").strip()
    city = doc.get("city", "").strip()
    district = doc.get("district", city).strip()
    state = doc.get("state", "").strip()
    university = (doc.get("universityName") or "").strip()
    courses = doc.get("courses") or []
    keywords = doc.get("searchKeywords") or []

    doc.setdefault("nameLower", name.lower())
    doc.setdefault("cityLower", city.lower())
    doc.setdefault("districtLower", district.lower())
    doc.setdefault("stateLower", state.lower())
    doc.setdefault("universityLower", university.lower())
    doc.setdefault("slug", re.sub(r"[^a-z0-9]+", "-", f"{name}-{city}".lower()).strip("-") or "college")
    doc.setdefault("isActive", True)
    doc.setdefault("reviewCount", 0)
    doc.setdefault("photoUrls", [])
    doc.setdefault("coursesDetailed", [])
    doc.setdefault("hostel", doc.get("hostel") or {"available": False})
    doc.setdefault("accreditation", doc.get("accreditation") or {})
    if not doc.get("searchTokens"):
        doc["searchTokens"] = build_search_tokens(
            name, city, district, state, university, courses, keywords
        )
    now = datetime.now(timezone.utc).isoformat()
    doc.setdefault("createdAt", now)
    doc.setdefault("updatedAt", now)
    return doc


def is_quota_error(exc: Exception) -> bool:
    msg = str(exc).lower()
    return any(
        k in msg
        for k in (
            "quota", "resource_exhausted", "429", "deadline_exceeded",
            "504", "stream removed", "unavailable", "timeout",
        )
    )


def commit_chunk(db, chunk: list, imported: int, delay: float) -> tuple[int, bool]:
    """Commit chunk with small batches; fall back to single-doc writes."""
    sub_size = 25
    done = 0
    for sub_start in range(0, len(chunk), sub_size):
        sub = chunk[sub_start : sub_start + sub_size]
        batch = db.batch()
        for raw in sub:
            doc = normalize_college(dict(raw))
            doc_id = doc.pop("id", None) or doc.get("slug") or f"college_{imported + done}"
            batch.set(db.collection("colleges").document(str(doc_id)), doc, merge=True)
        committed = False
        for attempt in range(15):
            try:
                batch.commit()
                done += len(sub)
                time.sleep(delay)
                committed = True
                break
            except Exception as exc:  # noqa: BLE001
                if is_quota_error(exc):
                    wait = min(300, 30 * (2 ** min(attempt, 4)))
                    print(f"Quota/timeout, waiting {wait}s (retry {attempt + 1}/15)...")
                    time.sleep(wait)
                    batch = db.batch()
                    for raw in sub:
                        doc = normalize_college(dict(raw))
                        doc_id = doc.pop("id", None) or doc.get("slug") or f"college_{imported + done}"
                        batch.set(db.collection("colleges").document(str(doc_id)), doc, merge=True)
                else:
                    time.sleep(delay * (attempt + 1))
        if committed:
            continue
        print(f"Batch failed; writing {len(sub)} docs one-by-one...")
        for raw in sub:
            for attempt in range(10):
                try:
                    doc = normalize_college(dict(raw))
                    doc_id = doc.pop("id", None) or doc.get("slug") or f"college_{imported + done}"
                    db.collection("colleges").document(str(doc_id)).set(doc, merge=True)
                    done += 1
                    time.sleep(max(delay, 2.0))
                    break
                except Exception as exc:  # noqa: BLE001
                    wait = 60 * (attempt + 1) if is_quota_error(exc) else 5
                    print(f"  single-doc retry {attempt + 1}, wait {wait}s")
                    time.sleep(wait)
            else:
                return done, False
    return done, True


def existing_ids_for_state(db, state: str | None) -> set[str]:
    ids: set[str] = set()
    q = db.collection("colleges")
    if state:
        q = q.where("state", "==", state)
    for doc in q.select([]).stream():
        ids.add(doc.id)
    return ids


def filter_missing(colleges: list[dict], existing: set[str]) -> list[dict]:
    missing: list[dict] = []
    for raw in colleges:
        doc_id = str(raw.get("id") or raw.get("slug") or "")
        if doc_id and doc_id not in existing:
            missing.append(raw)
    return missing


def main() -> int:
    parser = argparse.ArgumentParser(description="Import colleges to Firestore")
    parser.add_argument("--input", required=True, help="Path to colleges JSON array")
    parser.add_argument("--project", default=None, help="Firebase project id")
    parser.add_argument("--credentials", default=None, help="Service account JSON path")
    parser.add_argument("--verify-state", default=None, help="Verify count for state after import")
    parser.add_argument("--only-missing", action="store_true", help="Skip docs already in Firestore")
    parser.add_argument("--delay", type=float, default=0.5, help="Seconds between batch commits")
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
        if args.credentials:
            cred = credentials.Certificate(args.credentials)
        else:
            cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {"projectId": args.project} if args.project else None)

    db = firestore.client()
    colleges = json.loads(input_path.read_text(encoding="utf-8"))
    if not isinstance(colleges, list):
        print("Input must be a JSON array of college objects", file=sys.stderr)
        return 1

    if args.only_missing:
        scope = args.verify_state
        print(f"Loading existing Firestore IDs{f' for {scope}' if scope else ''}...")
        existing = existing_ids_for_state(db, scope)
        colleges = filter_missing(colleges, existing)
        print(f"Missing colleges to import: {len(colleges)}")

    if not colleges:
        print("Nothing to import.")
        if args.verify_state:
            q = db.collection("colleges").where("state", "==", args.verify_state)
            count = int(q.count().get()[0][0].value)
            print(f"Verified {args.verify_state} documents in Firestore: {count}")
        return 0

    batch_size = 100
    imported = 0
    errors: list[str] = []
    delay = max(args.delay, 2.5)

    for i in range(0, len(colleges), batch_size):
        chunk = colleges[i : i + batch_size]
        n, ok = commit_chunk(db, chunk, imported, delay)
        if not ok:
            errors.append(f"batch {i}-{i + batch_size}")
            print(f"Stopping import at batch {i} due to repeated failures", file=sys.stderr)
            break
        imported += n
        print(f"Imported {imported}/{len(colleges)}")

    db.collection("_meta").document("collegeDirectory").set(
        {
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        },
        merge=True,
    )
    print(f"Done. {imported} colleges imported.")
    if errors:
        print(f"Completed with {len(errors)} batch error(s)", file=sys.stderr)
        return 2
    if args.verify_state:
        q = db.collection("colleges").where("state", "==", args.verify_state)
        count = int(q.count().get()[0][0].value)
        print(f"Verified {args.verify_state} documents in Firestore: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
