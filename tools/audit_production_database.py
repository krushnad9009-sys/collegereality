#!/usr/bin/env python3
"""Read-only production database audit for College Reality. Does not modify data."""
from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
FULL_JSON = ROOT / "tools/data/firestore/india_colleges_firestore_full.json"
LEGACY_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"
OUT_JSON = ROOT / "tools/data/audit_evidence.json"
SEED_FILES = [
    ROOT / "assets/data/colleges_seed.json",
    ROOT / "assets/data/prominent_colleges_seed.json",
    ROOT / "assets/data/india_colleges_seed.json",
    ROOT / "assets/data/maharashtra_colleges_seed.json",
]

MANDATORY = ["id", "name", "city", "state", "category", "type"]
SEARCH_FIELDS = [
    "name", "nameLower", "city", "cityLower", "state", "stateLower",
    "universityName", "universityLower", "courses", "category", "type",
    "ownership", "searchTokens", "isActive",
]
CATEGORIES = [
    "Engineering", "Medical", "MBA", "Pharmacy", "Nursing", "Law",
    "Commerce", "Arts", "Science", "General", "Polytechnic",
    "Agriculture", "Architecture", "Fashion",
]


def nonempty(v) -> bool:
    if v is None:
        return False
    if isinstance(v, (list, dict)):
        return len(v) > 0
    return str(v).strip() not in ("", "null", "None")


def load_json_colleges(path: Path) -> list[dict]:
    print(f"Loading {path} ...", flush=True)
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit(f"Expected list in {path}")
    print(f"  loaded {len(data)} records", flush=True)
    return data


def analyze_records(records: list[dict], source_label: str) -> dict:
    ids = []
    name_city_state_keys = []
    by_state = Counter()
    by_city = Counter()
    by_category = Counter()
    by_type = Counter()
    missing_fields = defaultdict(list)
    invalid = []
    no_tokens = []
    empty_tokens = []
    inactive = 0
    active = 0
    search_field_coverage = {f: 0 for f in SEARCH_FIELDS}
    pune = 0
    mumbai = 0

    for i, rec in enumerate(records):
        rid = str(rec.get("id") or "").strip()
        ids.append(rid)
        name = str(rec.get("name") or "").strip()
        city = str(rec.get("city") or "").strip()
        state = str(rec.get("state") or "").strip()
        category = str(rec.get("category") or "").strip()
        ctype = str(rec.get("type") or "").strip()
        city_l = str(rec.get("cityLower") or city.lower()).strip().lower()
        name_l = str(rec.get("nameLower") or name.lower()).strip().lower()

        by_state[state or "<missing>"] += 1
        by_city[city or "<missing>"] += 1
        by_category[category or "<missing>"] += 1
        by_type[ctype or "<missing>"] += 1

        if city_l in ("pune", "poona") or city_l.endswith(" pune") or city_l.startswith("pune "):
            pune += 1
        elif "pune" == city_l:
            pune += 1
        if "pune" in city_l.split() or city_l in ("pune", "poona"):
            pass
        if city_l in ("pune", "poona") or city_l == "pune":
            pass
        # recount cleanly
        if city_l in ("pune", "poona"):
            pass

        is_active = rec.get("isActive", True)
        if is_active is False:
            inactive += 1
        else:
            active += 1

        for f in SEARCH_FIELDS:
            if nonempty(rec.get(f)):
                search_field_coverage[f] += 1

        for f in MANDATORY:
            if not nonempty(rec.get(f)):
                if len(missing_fields[f]) < 8:
                    missing_fields[f].append({
                        "id": rid or f"index:{i}",
                        "name": name[:80],
                        "city": city,
                        "state": state,
                    })
                missing_fields[f + "__count"] = missing_fields.get(f + "__count", 0) + 1

        tokens = rec.get("searchTokens")
        if tokens is None:
            if len(no_tokens) < 8:
                no_tokens.append({"id": rid, "name": name[:80], "city": city})
        elif isinstance(tokens, list) and len(tokens) == 0:
            if len(empty_tokens) < 8:
                empty_tokens.append({"id": rid, "name": name[:80], "city": city})

        reasons = []
        if not rid:
            reasons.append("missing_id")
        if not name:
            reasons.append("missing_name")
        if not city:
            reasons.append("missing_city")
        if not state:
            reasons.append("missing_state")
        if not category:
            reasons.append("missing_category")
        if name and len(name) < 2:
            reasons.append("name_too_short")
        if reasons and len(invalid) < 15:
            invalid.append({"id": rid, "name": name[:80], "reasons": reasons})

        name_city_state_keys.append(f"{name_l}|{city_l}|{state.lower()}")

    # Fix pune/mumbai counts properly
    pune = 0
    mumbai = 0
    for rec in records:
        city_l = str(rec.get("cityLower") or rec.get("city") or "").strip().lower()
        if city_l in ("pune", "poona") or city_l.startswith("pune ") or " pune" in city_l:
            pune += 1
        if city_l in ("mumbai", "bombay") or city_l.startswith("mumbai ") or " mumbai" in city_l:
            mumbai += 1

    id_counts = Counter(ids)
    dup_ids = [{"id": k, "count": v} for k, v in id_counts.items() if k and v > 1]
    dup_ids.sort(key=lambda x: -x["count"])
    empty_id_count = id_counts.get("", 0)

    ncs_counts = Counter(name_city_state_keys)
    dup_ncs = [{"key": k, "count": v} for k, v in ncs_counts.items() if v > 1 and k.count("|") == 2 and not k.startswith("|")]
    dup_ncs.sort(key=lambda x: -x["count"])

    dup_samples = []
    for item in dup_ncs[:10]:
        key = item["key"]
        samples = []
        for rec in records:
            name = str(rec.get("name") or "").strip().lower()
            city = str(rec.get("cityLower") or rec.get("city") or "").strip().lower()
            state = str(rec.get("state") or "").strip().lower()
            if f"{name}|{city}|{state}" == key:
                samples.append({
                    "id": rec.get("id"),
                    "name": rec.get("name"),
                    "city": rec.get("city"),
                    "state": rec.get("state"),
                })
                if len(samples) >= 3:
                    break
        dup_samples.append({"key": key, "count": item["count"], "samples": samples})

    missing_summary = {}
    for f in MANDATORY:
        missing_summary[f] = {
            "count": missing_fields.get(f + "__count", 0),
            "samples": missing_fields.get(f, []),
        }

    no_tokens_n = sum(1 for r in records if r.get("searchTokens") is None)
    empty_tokens_n = sum(
        1 for r in records
        if isinstance(r.get("searchTokens"), list) and len(r.get("searchTokens")) == 0
    )
    invalid_n = sum(
        1 for rec in records
        if (not nonempty(rec.get("id")) or not nonempty(rec.get("name"))
            or not nonempty(rec.get("city")) or not nonempty(rec.get("state"))
            or not nonempty(rec.get("category")))
    )

    cat_counts = {c: by_category.get(c, 0) for c in CATEGORIES}
    cat_counts["<other_or_missing>"] = sum(v for k, v in by_category.items() if k not in CATEGORIES)

    return {
        "source": source_label,
        "total_records": len(records),
        "unique_nonempty_ids": len([k for k in id_counts if k]),
        "empty_id_count": empty_id_count,
        "duplicate_id_groups": len(dup_ids),
        "duplicate_id_extra_docs": sum(d["count"] - 1 for d in dup_ids),
        "duplicate_ids_top": dup_ids[:20],
        "duplicate_college_groups_name_city_state": len(dup_ncs),
        "duplicate_college_extra": sum(i["count"] - 1 for i in dup_ncs),
        "duplicate_college_top": dup_ncs[:20],
        "duplicate_college_samples": dup_samples,
        "active": active,
        "inactive": inactive,
        "by_state": by_state.most_common(),
        "by_city_top50": by_city.most_common(50),
        "by_category": by_category.most_common(),
        "by_type": by_type.most_common(),
        "category_targets": cat_counts,
        "pune_count": pune,
        "mumbai_count": mumbai,
        "missing_mandatory": missing_summary,
        "invalid_record_count": invalid_n,
        "invalid_samples": invalid,
        "search_field_coverage": {
            f: {"present": search_field_coverage[f], "missing": len(records) - search_field_coverage[f]}
            for f in SEARCH_FIELDS
        },
        "missing_searchTokens_count": no_tokens_n,
        "empty_searchTokens_count": empty_tokens_n,
        "missing_searchTokens_samples": no_tokens[:8],
        "empty_searchTokens_samples": empty_tokens[:8],
    }


def query_live_firestore(creds: Path) -> dict:
    import firebase_admin
    from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(creds)),
        {"projectId": "college-reality"},
    )
    db = firestore.client()
    print("Querying live Firestore college-reality / colleges ...", flush=True)

    total = int(db.collection("colleges").count().get()[0][0].value)
    print(f"  total count aggregation = {total}", flush=True)

    meta_summary = {}
    try:
        snap = db.collection("_meta").document("collegeDirectory").get()
        if snap.exists:
            meta = snap.to_dict() or {}
            meta_summary = {
                "totalColleges": meta.get("totalColleges"),
                "updatedAt": str(meta.get("updatedAt")),
                "states_count": len(meta.get("states") or []),
                "courses_count": len(meta.get("courses") or []),
                "categoryCounts": meta.get("categoryCounts"),
                "stateCounts": meta.get("stateCounts"),
            }
        else:
            meta_summary = {"exists": False}
    except Exception as exc:  # noqa: BLE001
        meta_summary = {"error": str(exc)}

    def qcount(field, value):
        try:
            return int(
                db.collection("colleges").where(field, "==", value).count().get()[0][0].value
            )
        except Exception as exc:  # noqa: BLE001
            return f"ERROR: {exc}"

    print("  streaming sample for field/index checks (up to 5000 docs)...", flush=True)
    sample = []
    for doc in db.collection("colleges").limit(5000).stream():
        d = doc.to_dict() or {}
        d["id"] = doc.id
        sample.append(d)
    print(f"  sampled {len(sample)} docs", flush=True)

    sample_analysis = analyze_records(sample, "firestore_live_sample_5000")

    targeted = {
        "cityLower_pune": qcount("cityLower", "pune"),
        "cityLower_mumbai": qcount("cityLower", "mumbai"),
        "city_Pune": qcount("city", "Pune"),
        "city_Mumbai": qcount("city", "Mumbai"),
        "category_Engineering": qcount("category", "Engineering"),
        "category_Medical": qcount("category", "Medical"),
        "category_MBA": qcount("category", "MBA"),
        "category_Pharmacy": qcount("category", "Pharmacy"),
        "category_Nursing": qcount("category", "Nursing"),
        "category_Law": qcount("category", "Law"),
        "category_Commerce": qcount("category", "Commerce"),
        "category_Arts": qcount("category", "Arts"),
        "isActive_true": qcount("isActive", True),
        "isActive_false": qcount("isActive", False),
    }

    state_counts_live = {}
    if isinstance(meta_summary.get("stateCounts"), dict):
        state_counts_live = meta_summary["stateCounts"]
    else:
        for st in ["Maharashtra", "Uttar Pradesh", "Karnataka", "Tamil Nadu", "Delhi", "West Bengal"]:
            state_counts_live[st] = qcount("state", st)

    return {
        "project": "college-reality",
        "collection": "colleges",
        "total_documents_count_aggregation": total,
        "meta_collegeDirectory": meta_summary,
        "targeted_counts": targeted,
        "state_counts_queried": state_counts_live,
        "sample_analysis": sample_analysis,
        "search_index_estimate": {
            "sample_size": len(sample),
            "sample_missing_searchTokens": sample_analysis["missing_searchTokens_count"],
            "sample_empty_searchTokens": sample_analysis["empty_searchTokens_count"],
            "sample_pct_missing_or_empty_tokens": round(
                100.0 * (
                    sample_analysis["missing_searchTokens_count"]
                    + sample_analysis["empty_searchTokens_count"]
                ) / max(len(sample), 1),
                2,
            ),
        },
    }


def analyze_bundled() -> dict:
    merged = {}
    per_file = {}
    for path in SEED_FILES:
        if not path.exists():
            per_file[path.name] = {"exists": False}
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        per_file[path.name] = {"exists": True, "records": len(data)}
        if path.name == "maharashtra_colleges_seed.json":
            continue
        for rec in data:
            rid = str(rec.get("id") or "")
            if rid:
                merged[rid] = rec
    analysis = analyze_records(list(merged.values()), "bundled_loadAll_merged")
    analysis["per_file"] = per_file
    analysis["note"] = (
        "CollegeBundledDataSource.loadAll merges colleges_seed + prominent + "
        "india_colleges_seed only; maharashtra seed excluded"
    )
    return analysis


def main() -> int:
    evidence = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "audit_mode": "read_only",
        "production_source": "Firestore project college-reality collection colleges",
        "fallback_source": "assets/data bundled JSON via CollegeBundledDataSource",
    }

    json_path = FULL_JSON if FULL_JSON.exists() else LEGACY_JSON
    if json_path.exists():
        export_records = load_json_colleges(json_path)
        evidence["firestore_export_json"] = analyze_records(
            export_records, str(json_path.relative_to(ROOT))
        )
    else:
        evidence["firestore_export_json"] = {"error": "export JSON missing"}

    if CREDS.exists() and CREDS.stat().st_size > 100:
        try:
            evidence["firestore_live"] = query_live_firestore(CREDS)
        except Exception as exc:  # noqa: BLE001
            evidence["firestore_live"] = {"error": str(exc)}
    else:
        evidence["firestore_live"] = {"error": "service account missing or empty"}

    evidence["bundled_fallback"] = analyze_bundled()

    prior = ROOT / "tools/data/import_final_report.json"
    if prior.exists():
        try:
            evidence["prior_import_final_report"] = json.loads(prior.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            evidence["prior_import_final_report"] = {"error": str(exc)}

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(evidence, indent=2, default=str), encoding="utf-8")
    print(f"Wrote {OUT_JSON}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())