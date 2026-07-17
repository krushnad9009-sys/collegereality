#!/usr/bin/env python3
"""Import all-India colleges from official AISHE open-government data.

Source: data.gov.in — Institutions (AISHE Survey) [NDSAP]

Outputs:
  - tools/data/processed/india_colleges_clean.csv
  - tools/data/firestore/india_colleges_firestore.json
  - assets/data/india_colleges_seed.json (curated dev subset)

Usage:
  python tools/import_india_aishe.py
  python tools/import_india_aishe.py --state Karnataka
  python tools/import_india_aishe.py --exclude-state Maharashtra
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import unicodedata
import urllib.request
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW_CSV = ROOT / "tools/data/raw/aishe_colleges_india.csv"
OUT_CSV = ROOT / "tools/data/processed/india_colleges_clean.csv"
OUT_JSON = ROOT / "tools/data/firestore/india_colleges_firestore.json"
OUT_JSON_FULL = ROOT / "tools/data/firestore/india_colleges_firestore_full.json"
OUT_JSON_STATE_DIR = ROOT / "tools/data/firestore/states"
OUT_SEED = ROOT / "assets/data/india_colleges_seed.json"

AISHE_CSV_URL = (
    "https://raw.githubusercontent.com/PriyanKishoreMS/colleges-api/master/data/colleges.csv"
)

SOURCE_NOTE = (
    "Source: AISHE Institution Directory via data.gov.in (NDSAP). "
    "Ministry of Education, Government of India."
)

CATEGORIES = [
    "Engineering",
    "MBA",
    "Law",
    "Pharmacy",
    "Polytechnic",
    "Arts",
    "Commerce",
    "Science",
    "Medical",
    "Nursing",
    "Agriculture",
    "Architecture",
    "Fashion",
    "General",
]

COURSE_BY_CATEGORY: dict[str, list[str]] = {
    "Engineering": ["B.Tech", "B.E.", "M.Tech"],
    "MBA": ["MBA", "BBA"],
    "Law": ["LLB"],
    "Pharmacy": ["B.Pharm"],
    "Polytechnic": ["B.Tech"],
    "Arts": ["BA"],
    "Commerce": ["B.Com"],
    "Science": ["B.Sc"],
    "Medical": ["MBBS", "BDS"],
    "Nursing": ["B.Sc"],
    "Agriculture": ["B.Sc"],
    "Architecture": ["B.Arch"],
    "Fashion": ["BA"],
    "General": ["BA", "B.Sc", "B.Com"],
}

NIRF_BY_CATEGORY: dict[str, str] = {
    "Engineering": "Engineering",
    "MBA": "Management",
    "Law": "Law",
    "Pharmacy": "Pharmacy",
    "Polytechnic": "Engineering",
    "Arts": "University",
    "Commerce": "Commerce",
    "Science": "University",
    "Medical": "Medical",
    "Nursing": "Medical",
    "Agriculture": "University",
    "Architecture": "Architecture",
    "Fashion": "University",
    "General": "University",
}

SEARCH_STOP_WORDS = frozenset({
    "the", "of", "and", "for", "in", "at", "to", "a", "an", "shri", "shree",
    "sri", "college", "institute", "school", "university", "mahavidyalaya",
    "mahavidyalay", "vidyalaya", "vidyalay", "sanstha", "trust", "society",
})

# Major cities per state for seed curation and featured flags.
MAJOR_CITIES_BY_STATE: dict[str, set[str]] = {
    "Maharashtra": {
        "mumbai", "pune", "nagpur", "nashik", "aurangabad", "thane", "kolhapur",
    },
    "Karnataka": {"bangalore", "bengaluru", "mysore", "mysuru", "mangalore", "hubli"},
    "Tamil Nadu": {"chennai", "coimbatore", "madurai", "trichy", "salem"},
    "Uttar Pradesh": {"lucknow", "kanpur", "noida", "ghaziabad", "agra", "varanasi"},
    "Delhi": {"delhi", "new delhi"},
    "Gujarat": {"ahmedabad", "surat", "vadodara", "rajkot"},
    "Rajasthan": {"jaipur", "jodhpur", "udaipur", "kota"},
    "West Bengal": {"kolkata", "howrah", "durgapur", "siliguri"},
    "Telangana": {"hyderabad", "warangal", "nizamabad"},
    "Andhra Pradesh": {"visakhapatnam", "vijayawada", "guntur", "tirupati"},
    "Kerala": {"thiruvananthapuram", "kochi", "kozhikode", "thrissur"},
    "Madhya Pradesh": {"bhopal", "indore", "jabalpur", "gwalior"},
    "Punjab": {"chandigarh", "ludhiana", "amritsar", "jalandhar"},
    "Haryana": {"gurgaon", "gurugram", "faridabad", "panipat"},
    "Bihar": {"patna", "gaya", "muzaffarpur"},
    "Odisha": {"bhubaneswar", "cuttack", "rourkela"},
    "Assam": {"guwahati", "dibrugarh", "silchar"},
    "Jharkhand": {"ranchi", "jamshedpur", "dhanbad"},
    "Chhatisgarh": {"raipur", "bilaspur", "durg"},
    "Uttrakhand": {"dehradun", "haridwar", "rishikesh"},
    "Himachal Pradesh": {"shimla", "dharamshala", "solan"},
    "Jammu and Kashmir": {"srinagar", "jammu"},
    "Goa": {"panaji", "margao", "vasco"},
}

NATIONAL_MAJOR_CITIES = {
    "mumbai", "pune", "delhi", "new delhi", "bangalore", "bengaluru", "chennai",
    "hyderabad", "kolkata", "ahmedabad", "jaipur", "lucknow", "nagpur", "noida",
    "gurgaon", "gurugram", "kochi", "bhopal", "indore", "chandigarh", "patna",
    "bhubaneswar", "guwahati", "dehradun", "visakhapatnam", "coimbatore",
}


def slugify(name: str, city: str, aishe_id: str) -> str:
    base = f"{name}-{city}".lower()
    base = re.sub(r"[^a-z0-9]+", "-", base).strip("-")
    if not base:
        base = f"college-{aishe_id}"
    return base[:80]


def title_case(text: str) -> str:
    text = re.sub(r"\s+", " ", text.strip())
    if not text:
        return text
    return " ".join(
        w[:1].upper() + w[1:].lower() if w else w
        for w in text.split(" ")
    )


def clean_name(name: str) -> str:
    name = unicodedata.normalize("NFKC", name or "")
    name = re.sub(r"\s+", " ", name.strip())
    name = re.sub(r"^[\d\-.\s]+", "", name)
    return name.upper() if name.isupper() else title_case(name)


def clean_city(city: str, district: str = "") -> str:
    city = re.sub(r"\s+", " ", (city or "").strip())
    city = re.sub(r"\d{5,6}$", "", city).strip(" ,-")
    if city in {"0", "00", "000"} or re.fullmatch(r"\d+", city or ""):
        city = ""
    if city.upper() in {"", "NA", "N/A", "-", "NIL", "NONE"}:
        city = district
    if city in {"0", "00"} or re.fullmatch(r"\d+", city or ""):
        city = district
    return title_case(city)


def clean_district(district: str, city: str) -> str:
    district = re.sub(r"\s+", " ", (district or "").strip())
    if district in {"0", "00"} or re.fullmatch(r"\d+", district or ""):
        district = city
    return title_case(district) if district else city


def clean_state(state: str) -> str:
    state = re.sub(r"\s+", " ", (state or "").strip())
    aliases = {
        "Orissa": "Odisha",
        "Uttaranchal": "Uttrakhand",
        "Chhattisgarh": "Chhatisgarh",
        "NCT of Delhi": "Delhi",
        "Delhi NCT": "Delhi",
    }
    return aliases.get(state, title_case(state))


def build_address(line1: str, line2: str, city: str, pin: str) -> str:
    parts = [p.strip() for p in [line1, line2, city, pin] if p and p.strip()]
    return ", ".join(parts)


def download_raw_csv(dest: Path, force: bool = False) -> None:
    if dest.exists() and not force and dest.stat().st_size > 1_000_000:
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading AISHE CSV -> {dest}")
    urllib.request.urlretrieve(AISHE_CSV_URL, dest)


def categorize(name: str) -> str:
    n = name.upper()
    rules: list[tuple[str, list[str]]] = [
        ("Nursing", ["NURSING", "NURSE", "ANM", "GNM"]),
        ("Fashion", ["FASHION", "DESIGN", "APPAREL", "TEXTILE DESIGN"]),
        ("Agriculture", ["AGRICULT", "AGRI ", "KRUSHI", "KRISHI", "HORTICULT"]),
        ("Pharmacy", ["PHARMACY", "PHARMACEUT", "B.PHARM", "PHARM "]),
        ("Medical", ["MEDICAL", "MBBS", "DENTAL", "BDS", "AYURVED", "HOMOEOP", "HOMOEOPATH", "HOSPITAL"]),
        ("Architecture", ["ARCHITECTURE", "ARCHITECT"]),
        ("Engineering", ["ENGINEERING", "TECHNOLOGY", " INSTITUTE OF TECH", " I.T.", "TECH "]),
        ("Polytechnic", ["POLYTECHNIC", "DIPLOMA INSTITUTE"]),
        ("MBA", ["MBA", "BUSINESS SCHOOL", "MANAGEMENT STUDIES", "MANAGEMENT COLLEGE", "MANAGEMENT INSTITUTE", "PGDM"]),
        ("Law", ["LAW", "LLB", "LEGAL", "JURIS"]),
        ("Commerce", ["COMMERCE", "B.COM", "COMM.", "ACCOUNTANCY"]),
        ("Science", ["SCIENCE COLLEGE", "SCIENCE AND", "B.SC", "PURE SCIENCE"]),
        ("Arts", ["ARTS COLLEGE", "ARTS AND", "FINE ARTS", "HUMANITIES"]),
    ]
    for category, keywords in rules:
        if any(k in n for k in keywords):
            return category
    if "MANAGEMENT" in n or "BBA" in n:
        return "MBA"
    if "ARTS" in n or "SCIENCE" in n:
        return "Arts"
    if "EDUCATION" in n or "B.ED" in n or "TEACHER" in n:
        return "General"
    return "General"


def infer_type(name: str, category: str) -> str:
    n = name.upper()
    if "DEEMED" in n:
        return "deemed"
    if "AUTONOMOUS" in n:
        return "autonomous"
    if any(k in n for k in ("GOVERNMENT", "GOVT", "MUNICIPAL", "PUBLIC", "STATE")):
        return "government"
    if category == "Polytechnic" and "GOVERNMENT" in n:
        return "government"
    return "private"


def build_search_tokens(
    name: str,
    city: str,
    district: str,
    state: str,
    category: str,
    courses: list[str],
    keywords: list[str],
) -> list[str]:
    tokens: set[str] = set()
    name_words = [
        w.lower()
        for w in re.split(r"\W+", name)
        if len(w) >= 2 and w.lower() not in SEARCH_STOP_WORDS
    ]
    for word in name_words[:8]:
        tokens.add(word)
        for length in range(3, min(len(word), 12) + 1):
            tokens.add(word[:length])
    corpus = " ".join([city, district, state, category, *courses, *keywords]).lower()
    for word in re.split(r"\W+", corpus):
        if len(word) < 2:
            continue
        tokens.add(word)
        for length in range(3, min(len(word), 12) + 1):
            tokens.add(word[:length])
    return sorted(tokens)[:30]


def row_to_college(row: dict[str, str], now: str, state_filter: str | None = None) -> dict | None:
    aishe_id = (row.get("id") or "").strip().lstrip("\ufeff")
    state = clean_state(row.get("state") or "")
    if not state or len(state) < 2:
        return None
    if state_filter and state.lower() != state_filter.lower():
        return None

    name = clean_name(row.get("name") or "")
    if len(name) < 4:
        return None

    district = clean_district(row.get("district") or "", "")
    city = clean_city(row.get("city") or "", district)
    district = clean_district(row.get("district") or "", city)
    if not city:
        city = district or state
    pin = (row.get("pin_code") or "").strip()
    address = build_address(
        row.get("address_line1") or "",
        row.get("address_line2") or "",
        city,
        pin,
    )

    category = categorize(name)
    college_type = infer_type(name, category)
    courses = COURSE_BY_CATEGORY.get(category, ["BA", "B.Sc"])
    doc_id = f"aishe_{aishe_id}"

    keywords = [
        state.lower(),
        city.lower(),
        district.lower(),
        category.lower(),
        college_type,
        "aishe",
        "india",
        *[w.lower() for w in re.split(r"\W+", name) if len(w) >= 3 and w.lower() not in SEARCH_STOP_WORDS][:6],
    ]

    slug = slugify(name, city, aishe_id)
    search_tokens = build_search_tokens(
        name, city, district, state, category, courses, keywords
    )

    return {
        "id": doc_id,
        "aisheId": aishe_id,
        "name": name,
        "nameLower": name.lower(),
        "slug": slug,
        "city": city,
        "district": district,
        "state": state,
        "cityLower": city.lower(),
        "districtLower": district.lower(),
        "stateLower": state.lower(),
        "address": address,
        "type": college_type,
        "category": category,
        "courses": courses,
        "coursesDetailed": [],
        "universityName": None,
        "website": None,
        "phone": None,
        "email": None,
        "logoUrl": None,
        "coverPhotoUrl": None,
        "photoUrls": [],
        "latitude": None,
        "longitude": None,
        "googleMapsUrl": None,
        "officialLinks": [],
        "fees": {"tuitionMin": 0, "tuitionMax": 0, "hostelAnnual": 0},
        "scholarships": [],
        "placements": {
            "highestPackageLpa": 0,
            "averagePackageLpa": 0,
            "placementPercentage": 0,
            "topRecruiters": [],
        },
        "hostel": {"available": False},
        "accreditation": {
            "naacGrade": None,
            "naacCycle": None,
            "nirfRank": None,
            "nirfCategory": NIRF_BY_CATEGORY.get(category, "University"),
            "ugcRecognized": True,
            "aicteApproved": category in {"Engineering", "MBA", "Pharmacy", "Polytechnic"},
        },
        "aggregatedRatings": {
            "overall": 0,
            "faculty": 0,
            "infrastructure": 0,
            "placements": 0,
            "campusLife": 0,
            "hostel": 0,
            "fees": 0,
        },
        "reviewCount": 0,
        "ratingDistribution": {},
        "searchKeywords": keywords,
        "searchTokens": search_tokens,
        "isActive": True,
        "isFeatured": False,
        "adminNotes": SOURCE_NOTE,
        "updatedBy": "aishe_import",
        "createdAt": now,
        "updatedAt": now,
    }


def dedupe_colleges(colleges: list[dict]) -> tuple[list[dict], list[dict]]:
    """Return (unique colleges, duplicate-ID extras with unique doc ids)."""
    seen_keys: set[str] = set()
    seen_ids: dict[str, list[dict]] = defaultdict(list)
    unique: list[dict] = []

    for college in colleges:
        key = (
            college["name"].lower(),
            college["city"].lower(),
            college.get("address", "").lower()[:60],
        )
        if key in seen_keys:
            continue
        seen_keys.add(key)
        unique.append(college)
        seen_ids[college["id"]].append(college)

    extras: list[dict] = []
    for doc_id, group in seen_ids.items():
        if len(group) <= 1:
            continue
        for c in group[1:]:
            nc = dict(c)
            nc["id"] = f"{doc_id}_{slugify(c['name'], c['city'], c['aisheId'])}"
            extras.append(nc)

    return unique, extras


def select_seed_subset(colleges: list[dict], limit: int) -> list[dict]:
    by_city: dict[str, list[dict]] = defaultdict(list)
    for c in colleges:
        by_city[c["city"].lower()].append(c)

    picked: list[dict] = []
    picked_ids: set[str] = set()

    def add(college: dict) -> None:
        if college["id"] in picked_ids:
            return
        picked_ids.add(college["id"])
        picked.append(college)

    for city in sorted(NATIONAL_MAJOR_CITIES):
        pool = by_city.get(city, [])
        if not pool:
            continue
        by_cat: dict[str, list[dict]] = defaultdict(list)
        for c in pool:
            by_cat[c["category"]].append(c)
        for cat_colleges in by_cat.values():
            add(cat_colleges[0])
            if len(picked) >= limit:
                return picked[:limit]

    for college in colleges:
        add(college)
        if len(picked) >= limit:
            break

    return picked[:limit]


def mark_featured(colleges: list[dict]) -> None:
    for c in colleges:
        state = c["state"]
        city_l = c["city"].lower()
        state_cities = MAJOR_CITIES_BY_STATE.get(state, set())
        is_major = city_l in state_cities or city_l in NATIONAL_MAJOR_CITIES
        if is_major and c["category"] in {"Engineering", "MBA", "Medical"}:
            if c["type"] in {"government", "autonomous", "deemed"}:
                c["isFeatured"] = True
        elif is_major and c["type"] == "government" and c["category"] == "Arts":
            c["isFeatured"] = True


def main() -> int:
    parser = argparse.ArgumentParser(description="Import all-India AISHE colleges")
    parser.add_argument("--input", default=str(RAW_CSV), help="Raw AISHE CSV path")
    parser.add_argument("--state", default=None, help="Process single state only")
    parser.add_argument("--exclude-state", default=None, help="Skip a state (e.g. already imported)")
    parser.add_argument("--seed-limit", type=int, default=500, help="Dev seed subset size")
    parser.add_argument("--download", action="store_true", help="Force re-download AISHE CSV")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists() or args.download:
        download_raw_csv(input_path, force=args.download)
    if not input_path.exists():
        print(f"Missing input: {input_path}")
        return 1

    now = datetime.now(timezone.utc).isoformat()
    colleges: list[dict] = []

    with input_path.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            college = row_to_college(row, now, state_filter=args.state)
            if college:
                if args.exclude_state and college["state"].lower() == args.exclude_state.lower():
                    continue
                colleges.append(college)

    colleges, id_extras = dedupe_colleges(colleges)
    colleges.extend(id_extras)
    colleges.sort(key=lambda c: (c["state"].lower(), c["city"].lower(), c["name"].lower()))
    mark_featured(colleges)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    csv_fields = [
        "aisheId", "name", "city", "district", "state", "address", "pin_code",
        "type", "category", "courses", "id",
    ]
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=csv_fields)
        writer.writeheader()
        for c in colleges:
            writer.writerow({
                "aisheId": c["aisheId"],
                "name": c["name"],
                "city": c["city"],
                "district": c["district"],
                "state": c["state"],
                "address": c["address"],
                "pin_code": "",
                "type": c["type"],
                "category": c["category"],
                "courses": ";".join(c["courses"]),
                "id": c["id"],
            })

    seed = select_seed_subset(colleges, args.seed_limit)

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(colleges, ensure_ascii=False, indent=2)
    if args.state:
        OUT_JSON_STATE_DIR.mkdir(parents=True, exist_ok=True)
        slug = re.sub(r"[^a-z0-9]+", "_", args.state.lower()).strip("_")
        state_path = OUT_JSON_STATE_DIR / f"{slug}.json"
        state_path.write_text(payload, encoding="utf-8")
        print(f"  State JSON: {state_path}")
    else:
        OUT_JSON.write_text(payload, encoding="utf-8")
        OUT_JSON_FULL.write_text(payload, encoding="utf-8")

    OUT_SEED.parent.mkdir(parents=True, exist_ok=True)
    OUT_SEED.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    states = Counter(c["state"] for c in colleges)
    cats = Counter(c["category"] for c in colleges)
    featured = sum(1 for c in colleges if c.get("isFeatured"))

    print(f"India colleges processed: {len(colleges)}")
    print(f"  States: {len(states)}")
    print(f"  Featured: {featured}")
    print(f"  Duplicate-ID extras: {len(id_extras)}")
    print(f"  Clean CSV: {OUT_CSV}")
    print(f"  Firestore JSON: {OUT_JSON}")
    print(f"  Dev seed ({len(seed)}): {OUT_SEED}")
    print(f"  Top states: {states.most_common(8)}")
    print(f"  Categories: {dict(cats.most_common(8))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
