#!/usr/bin/env python3
"""Generate production-ready college JSON for bulk Firestore import.

This replaces the old 100-college demo seeder bundled in the Flutter app.
Use import_colleges_bulk.py to upload the output to Firestore.

  python tools/generate_colleges.py --count 40000 --output tools/colleges_export.json
"""

from __future__ import annotations

import argparse
import json
import random
import re
from pathlib import Path

STATES = [
    ("Mumbai", "Maharashtra"),
    ("Pune", "Maharashtra"),
    ("Delhi", "Delhi"),
    ("Bangalore", "Karnataka"),
    ("Chennai", "Tamil Nadu"),
    ("Hyderabad", "Telangana"),
    ("Kolkata", "West Bengal"),
    ("Ahmedabad", "Gujarat"),
    ("Jaipur", "Rajasthan"),
    ("Lucknow", "Uttar Pradesh"),
]

PREFIXES = [
    "National", "Global", "Indian", "Central", "Premier", "City", "Metro",
    "Institute of", "College of", "School of",
]
SUFFIXES = [
    "Engineering", "Technology", "Management", "Arts & Science", "Commerce",
    "Medical Sciences", "Pharmacy", "Law", "Education",
]
TYPES = ["government", "private", "deemed", "autonomous"]
COURSES = ["B.Tech", "BBA", "BCA", "B.Com", "B.Sc", "MBA", "M.Tech", "MBBS"]


def slugify(name: str, city: str) -> str:
    base = f"{name}-{city}".lower()
    base = re.sub(r"[^a-z0-9]+", "-", base).strip("-")
    return base or "college"


def build_college(index: int) -> dict:
    city, state = random.choice(STATES)
    name = f"{random.choice(PREFIXES)} {random.choice(SUFFIXES)} {index:05d}"
    name_lower = name.lower()
    college_type = random.choice(TYPES)
    courses = random.sample(COURSES, k=random.randint(2, 5))
    tuition_min = random.randint(40000, 150000)
    tuition_max = tuition_min + random.randint(20000, 120000)

    return {
        "id": f"college_{index:06d}",
        "name": name,
        "nameLower": name_lower,
        "slug": slugify(name, city),
        "city": city,
        "state": state,
        "address": f"{random.randint(1, 200)} University Road, {city}, {state}",
        "type": college_type,
        "universityName": f"{state} Technical University",
        "website": f"https://www.example-college-{index}.edu.in",
        "logoUrl": None,
        "coverPhotoUrl": None,
        "photoUrls": [],
        "latitude": round(random.uniform(8.0, 32.0), 5),
        "longitude": round(random.uniform(72.0, 88.0), 5),
        "courses": courses,
        "fees": {
            "tuitionMin": tuition_min,
            "tuitionMax": tuition_max,
            "hostelAnnual": random.randint(30000, 120000),
        },
        "hostel": {
            "available": random.choice([True, False]),
            "boysHostel": True,
            "girlsHostel": True,
            "acAvailable": random.choice([True, False]),
            "messIncluded": True,
            "annualFee": random.randint(30000, 120000),
            "amenities": ["Wi-Fi", "Mess", "Library"],
        },
        "placements": {
            "highestPackageLpa": round(random.uniform(5, 40), 1),
            "averagePackageLpa": round(random.uniform(3, 12), 1),
            "placementPercentage": random.randint(40, 95),
            "topRecruiters": random.sample(
                ["TCS", "Infosys", "Wipro", "Amazon", "Deloitte"], k=3
            ),
        },
        "accreditation": {
            "naacGrade": random.choice(["A++", "A+", "A", "B++", "B+"]),
            "nirfRank": random.randint(1, 500) if random.random() > 0.5 else None,
            "nirfCategory": random.choice(["Engineering", "University", "Management"]),
            "ugcRecognized": True,
            "aicteApproved": college_type in {"private", "deemed"},
        },
        "aggregatedRatings": {
            "overall": round(random.uniform(2.5, 4.8), 1),
            "faculty": round(random.uniform(2.5, 4.8), 1),
            "infrastructure": round(random.uniform(2.5, 4.8), 1),
            "placements": round(random.uniform(2.5, 4.8), 1),
            "campusLife": round(random.uniform(2.5, 4.8), 1),
            "hostel": round(random.uniform(2.0, 4.5), 1),
            "fees": round(random.uniform(2.0, 4.5), 1),
        },
        "reviewCount": 0,
        "scholarships": [],
        "searchKeywords": [city.lower(), state.lower(), *courses],
        "isActive": True,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=100, help="Number of colleges")
    parser.add_argument(
        "--output",
        default="tools/colleges_export.json",
        help="Output JSON path",
    )
    args = parser.parse_args()

    colleges = [build_college(i + 1) for i in range(args.count)]
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(colleges, indent=2), encoding="utf-8")
    print(f"Wrote {len(colleges)} colleges to {out}")


if __name__ == "__main__":
    main()
