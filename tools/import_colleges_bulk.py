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

ROOT = Path(__file__).resolve().parent.parent
STATS_PATH = ROOT / "tools/data/import_session_stats.json"


def infer_ownership(college_type: str) -> str:
    t = (college_type or "").lower()
    if "deemed" in t:
        return "Deemed"
    if "autonomous" in t:
        return "Autonomous"
    if any(k in t for k in ("government", "govt", "public")):
        return "Government"
    if "private" in t:
        return "Private"
    return "Private"


def infer_university_name(name: str, state: str, city: str) -> str:
    n = (name or "").strip()
    if re.search(r"\buniversity\b", n, re.I):
        return n[:120]
    if re.search(r"\bdeemed\b", n, re.I):
        return n[:120]
    return f"Affiliated to {state} State University"


def validate_college(doc: dict) -> tuple[bool, list[str]]:
    missing: list[str] = []
    name = (doc.get("name") or "").strip()
    state = (doc.get("state") or "").strip()
    district = (doc.get("district") or "").strip()
    city = (doc.get("city") or "").strip()
    if len(name) < 4:
        missing.append("name")
    if len(state) < 2:
        missing.append("state")
    if len(district) < 2 and len(city) < 2:
        missing.append("district/city")
    if not (doc.get("universityName") or "").strip():
        missing.append("universityName")
    if not (doc.get("type") or "").strip():
        missing.append("type")
    if not (doc.get("ownership") or "").strip():
        missing.append("ownership")
    courses = doc.get("courses") or []
    if not courses:
        missing.append("courses")
    address = (doc.get("address") or "").strip()
    if len(address) < 5 and not (city and state):
        missing.append("location")
    return len(missing) == 0, missing


def duplicate_key(doc: dict) -> tuple[str, str, str]:
    return (
        (doc.get("name") or "").strip().lower(),
        (doc.get("state") or "").strip().lower(),
        (doc.get("city") or "").strip().lower(),
    )


def load_existing_keys(db, state: str | None = None) -> tuple[set[str], set[tuple[str, str, str]], dict[str, str]]:
    """Return (doc_ids in scope, name+state+city keys in scope, aisheId->state)."""
    doc_ids: set[str] = set()
    name_keys: set[tuple[str, str, str]] = set()
    aishe_state: dict[str, str] = {}
    q = db.collection("colleges")
    if state:
        q = q.where("state", "==", state)
    for doc in q.select(["name", "state", "city", "aisheId"]).stream():
        doc_ids.add(doc.id)
        data = doc.to_dict() or {}
        name_keys.add(duplicate_key(data))
        aid = str(data.get("aisheId") or "").strip()
        if aid:
            aishe_state[aid] = str(data.get("state") or "")
    return doc_ids, name_keys, aishe_state


def filter_duplicates(
    colleges: list[dict],
    doc_ids: set[str],
    name_keys: set[tuple[str, str, str]],
    aishe_state: dict[str, str],
) -> tuple[list[dict], int]:
    """Skip duplicates by AISHE ID (same state), doc ID, then name+state+city."""
    unique: list[dict] = []
    skipped = 0
    batch_aishe: set[str] = set()
    batch_names: set[tuple[str, str, str]] = set()
    for raw in colleges:
        doc_id = str(raw.get("id") or raw.get("slug") or "")
        aid = str(raw.get("aisheId") or "").strip()
        state = (raw.get("state") or "").strip()
        nkey = duplicate_key(raw)
        if doc_id and doc_id in doc_ids:
            skipped += 1
            continue
        if aid and aid in aishe_state and aishe_state[aid].lower() == state.lower():
            skipped += 1
            continue
        if aid and aid in batch_aishe:
            skipped += 1
            continue
        if nkey[0] and nkey in name_keys:
            skipped += 1
            continue
        if nkey[0] and nkey in batch_names:
            skipped += 1
            continue
        unique.append(raw)
        if aid:
            batch_aishe.add(aid)
        if nkey[0]:
            batch_names.add(nkey)
    return unique, skipped


def repair_state_fields(db, colleges: list[dict], delay: float = 1.0) -> int:
    """Update docs that exist globally but have wrong state (fixes under-counted states)."""
    repaired = 0
    batch = db.batch()
    n = 0
    for raw in colleges:
        doc_id = str(raw.get("id") or raw.get("slug") or "")
        if not doc_id:
            continue
        ref = db.collection("colleges").document(doc_id)
        try:
            snap = ref.get()
        except Exception:  # noqa: BLE001
            continue
        if not snap.exists:
            continue
        data = snap.to_dict() or {}
        expected_state = (raw.get("state") or "").strip()
        if not expected_state or data.get("state") == expected_state:
            continue
        doc = normalize_college(dict(raw))
        patch = {
            "state": doc["state"],
            "stateLower": doc["stateLower"],
            "city": doc["city"],
            "cityLower": doc["cityLower"],
            "district": doc["district"],
            "districtLower": doc["districtLower"],
            "searchTokens": doc["searchTokens"],
            "searchKeywords": doc["searchKeywords"],
            "updatedAt": doc["updatedAt"],
        }
        batch.set(ref, patch, merge=True)
        n += 1
        repaired += 1
        if n >= 100:
            for attempt in range(10):
                try:
                    batch.commit()
                    time.sleep(delay)
                    break
                except Exception as exc:  # noqa: BLE001
                    if is_quota_error(exc):
                        time.sleep(min(300, 30 * (2 ** attempt)))
                    else:
                        time.sleep(delay)
            batch = db.batch()
            n = 0
    if n:
        batch.commit()
    return repaired


def load_stats() -> dict:
    if STATS_PATH.exists():
        try:
            return json.loads(STATS_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    return {
        "newlyImported": 0,
        "skippedDuplicates": 0,
        "failedImports": 0,
        "validationFailures": [],
        "sessions": [],
    }


def save_stats(stats: dict) -> None:
    STATS_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATS_PATH.write_text(json.dumps(stats, indent=2), encoding="utf-8")


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
    district = doc.get("district", city).strip() or city
    state = doc.get("state", "").strip()
    if not city and district:
        city = district
    if not district and city:
        district = city
    college_type = (doc.get("type") or "private").strip()
    if not (doc.get("universityName") or "").strip():
        doc["universityName"] = infer_university_name(name, state, city)
    if not (doc.get("ownership") or "").strip():
        doc["ownership"] = infer_ownership(college_type)
    if not (doc.get("address") or "").strip() and city and state:
        doc["address"] = f"{city}, {state}"
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


def filter_missing_by_lookup(db, colleges: list[dict], batch_size: int = 100) -> list[dict]:
    """Check existence by document ID in batches (fewer reads than full state stream)."""
    missing: list[dict] = []
    for i in range(0, len(colleges), batch_size):
        chunk = colleges[i : i + batch_size]
        refs = []
        ordered: list[dict] = []
        for raw in chunk:
            doc_id = str(raw.get("id") or raw.get("slug") or "")
            if not doc_id:
                missing.append(raw)
                continue
            refs.append(db.collection("colleges").document(doc_id))
            ordered.append(raw)
        if not refs:
            continue
        try:
            snaps = db.get_all(refs)
        except Exception as exc:  # noqa: BLE001
            if is_quota_error(exc):
                for attempt in range(12):
                    wait = min(300, 30 * (2 ** min(attempt, 4)))
                    print(f"Quota on doc lookup, waiting {wait}s...")
                    time.sleep(wait)
                    try:
                        snaps = db.get_all(refs)
                        break
                    except Exception as retry_exc:  # noqa: BLE001
                        if not is_quota_error(retry_exc) or attempt == 11:
                            raise
                else:
                    raise
            else:
                raise
        for raw, snap in zip(ordered, snaps):
            if not snap.exists:
                missing.append(raw)
    return missing


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
    parser.add_argument("--repair-state", action="store_true", help="Fix state field on existing docs")
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

    stats = load_stats()
    session = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "input": str(input_path),
        "state": args.verify_state,
        "newlyImported": 0,
        "skippedDuplicates": 0,
        "failedImports": 0,
        "validationFailures": [],
    }

    if args.only_missing or args.repair_state:
        scope = args.verify_state
        print(f"Checking missing colleges{f' for {scope}' if scope else ''}...")
        try:
            colleges = filter_missing_by_lookup(db, colleges)
            print(f"Missing colleges to import: {len(colleges)}")
            if args.repair_state and scope:
                all_state = json.loads(input_path.read_text(encoding="utf-8"))
                repaired = repair_state_fields(db, all_state, delay=max(args.delay, 2.0))
                session["repairedStateFields"] = repaired
                print(f"Repaired state field on {repaired} document(s)")
            if colleges and args.only_missing:
                doc_ids, name_keys, aishe_state = load_existing_keys(db, scope)
                colleges, dup_skip = filter_duplicates(colleges, doc_ids, name_keys, aishe_state)
                session["skippedDuplicates"] += dup_skip
                print(f"Skipped {dup_skip} duplicate(s) after missing-doc filter")
                print(f"Colleges to import after dedup: {len(colleges)}")
        except Exception as exc:  # noqa: BLE001
            if is_quota_error(exc):
                print(f"Quota exceeded while checking existing docs: {exc}", file=sys.stderr)
                return 2
            raise

    valid: list[dict] = []
    for raw in colleges:
        doc = normalize_college(dict(raw))
        ok, missing = validate_college(doc)
        if ok:
            valid.append(doc)
        else:
            session["validationFailures"].append(
                {"id": raw.get("id"), "name": raw.get("name"), "missing": missing}
            )
            print(f"Validation skip {raw.get('id')}: missing {missing}", file=sys.stderr)
    colleges = valid
    print(f"Validated colleges ready: {len(colleges)}")

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
            failed = len(chunk) - n
            session["failedImports"] += failed
            errors.append(f"batch {i}-{i + batch_size}")
            print(f"Stopping import at batch {i} due to repeated failures", file=sys.stderr)
            imported += n
            break
        imported += n
        print(f"Imported {imported}/{len(colleges)}")

    session["newlyImported"] = imported
    stats["newlyImported"] = stats.get("newlyImported", 0) + imported
    stats["skippedDuplicates"] = stats.get("skippedDuplicates", 0) + session["skippedDuplicates"]
    stats["failedImports"] = stats.get("failedImports", 0) + session["failedImports"]
    stats.setdefault("validationFailures", []).extend(session["validationFailures"])
    stats.setdefault("sessions", []).append(session)
    save_stats(stats)

    db.collection("_meta").document("collegeDirectory").set(
        {
            "updatedAt": datetime.now(timezone.utc).isoformat(),
            "lastImportSession": session,
        },
        merge=True,
    )
    print(f"Done. {imported} colleges imported.")
    print(f"Session stats: imported={imported}, skipped_dup={session['skippedDuplicates']}, failed={session['failedImports']}")
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
