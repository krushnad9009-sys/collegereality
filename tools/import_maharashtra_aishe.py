#!/usr/bin/env python3
"""Import Maharashtra colleges from official AISHE open-government data.

Source: data.gov.in — Institutions (AISHE Survey) [NDSAP]
Raw file: tools/data/raw/aishe_colleges_india.csv

Outputs:
  - tools/data/processed/maharashtra_colleges_clean.csv
  - tools/data/firestore/maharashtra_colleges_firestore.json
  - assets/data/maharashtra_colleges_seed.json (curated dev subset)

Usage:
  python tools/import_maharashtra_aishe.py
  python tools/import_maharashtra_aishe.py --seed-limit 400
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
OUT_CSV = ROOT / "tools/data/processed/maharashtra_colleges_clean.csv"
OUT_JSON = ROOT / "tools/data/firestore/maharashtra_colleges_firestore.json"
OUT_SEED = ROOT / "assets/data/maharashtra_colleges_seed.json"

AISHE_CSV_URL = (
    "https://raw.githubusercontent.com/PriyanKishoreMS/colleges-api/master/data/colleges.csv"
)

SOURCE_NOTE = (
    "Source: AISHE Institution Directory via data.gov.in (NDSAP). "
    "Ministry of Education, Government of India."
)

# User-facing category labels
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

MAJOR_CITIES = {
    "mumbai", "pune", "nagpur", "nashik", "aurangabad", "thane", "kolhapur",
    "solapur", "amravati", "nanded", "sangli", "jalgaon", "akola", "latur",
    "dhule", "ahmednagar", "chandrapur", "parbhani", "ichalkaranji", "jalna",
    "ambarnath", "bhiwandi", "ulhasnagar", "panvel", "satara", "ratnagiri",
    "yavatmal", "wardha", "gondia", "buldhana", "osmanabad", "beed",
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
    if city.upper() in {"", "NA", "N/A", "-", "NIL", "NONE"}:
        city = district
    return title_case(city)


def clean_district(district: str, city: str) -> str:
    district = re.sub(r"\s+", " ", (district or "").strip())
    return title_case(district) if district else city


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
    """Map college name to one of the user-facing category labels."""
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


def row_to_college(row: dict[str, str], now: str) -> dict | None:
    aishe_id = (row.get("id") or "").strip().lstrip("\ufeff")
    state = (row.get("state") or "").strip()
    if state != "Maharashtra":
        return None

    name = clean_name(row.get("name") or "")
    if len(name) < 4:
        return None

    city = clean_city(row.get("city") or "", row.get("district") or "")
    district = clean_district(row.get("district") or "", city)
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
        "maharashtra",
        city.lower(),
        district.lower(),
        category.lower(),
        college_type,
        "aishe",
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


def dedupe_colleges(colleges: list[dict]) -> list[dict]:
    seen: set[str] = set()
    unique: list[dict] = []
    for college in colleges:
        key = (
            college["name"].lower(),
            college["city"].lower(),
            college.get("address", "").lower()[:60],
        )
        if key in seen:
            continue
        seen.add(key)
        unique.append(college)
    return unique


def select_seed_subset(colleges: list[dict], limit: int) -> list[dict]:
    """Curated subset: major cities + category diversity for dev bootstrap."""
    by_city: dict[str, list[dict]] = defaultdict(list)
    for c in colleges:
        city_key = c["city"].lower()
        by_city[city_key].append(c)

    picked: list[dict] = []
    picked_ids: set[str] = set()

    def add(college: dict) -> None:
        if college["id"] in picked_ids:
            return
        picked_ids.add(college["id"])
        picked.append(college)

    # Prioritize major cities
    for city in sorted(MAJOR_CITIES):
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

    # Fill remaining slots
    for college in colleges:
        add(college)
        if len(picked) >= limit:
            break

    return picked[:limit]


def main() -> int:
    parser = argparse.ArgumentParser(description="Import Maharashtra AISHE colleges")
    parser.add_argument("--input", default=str(RAW_CSV), help="Raw AISHE CSV path")
    parser.add_argument("--seed-limit", type=int, default=300, help="Dev seed subset size")
    parser.add_argument("--download", action="store_true", help="Force re-download AISHE CSV")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists() or args.download:
        download_raw_csv(input_path, force=args.download)
    if not input_path.exists():
        print(f"Missing input: {input_path}")
        print("Download from data.gov.in AISHE catalog into tools/data/raw/")
        return 1

    now = datetime.now(timezone.utc).isoformat()
    colleges: list[dict] = []

    with input_path.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            college = row_to_college(row, now)
            if college:
                colleges.append(college)

    colleges = dedupe_colleges(colleges)
    colleges.sort(key=lambda c: (c["city"].lower(), c["name"].lower()))

    # Write cleaned CSV
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

    # Dev seed subset
    seed = select_seed_subset(colleges, args.seed_limit)

    # Mark featured colleges for home carousel / discovery
    featured_cities = {"mumbai", "pune", "nagpur", "nashik", "aurangabad"}
    for c in seed:
        city_l = c["city"].lower()
        if city_l in featured_cities and c["category"] in {
            "Engineering", "MBA", "Medical"
        }:
            c["isFeatured"] = True
        elif c["type"] == "government" and city_l in featured_cities:
            c["isFeatured"] = True

    for c in colleges:
        city_l = c["city"].lower()
        if city_l in featured_cities and c["category"] == "Engineering":
            if c["type"] in {"government", "autonomous", "deemed"}:
                c["isFeatured"] = True

    # Full Firestore JSON (after featured flags)
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(
        json.dumps(colleges, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    OUT_SEED.parent.mkdir(parents=True, exist_ok=True)
    OUT_SEED.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    cats = Counter(c["category"] for c in colleges)
    types = Counter(c["type"] for c in colleges)
    cities = Counter(c["city"] for c in colleges)

    print(f"Maharashtra colleges processed: {len(colleges)}")
    print(f"  Clean CSV: {OUT_CSV}")
    print(f"  Firestore JSON: {OUT_JSON}")
    print(f"  Dev seed ({len(seed)}): {OUT_SEED}")
    print(f"  Categories: {dict(cats.most_common(8))}")
    print(f"  Types: {dict(types)}")
    print(f"  Top cities: {cities.most_common(10)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
