#!/usr/bin/env python3
"""Enrich college logos and campus images from Wikimedia Commons (public domain).

Updates Firestore coverPhotoUrl/logoUrl for colleges missing images.
Prioritizes featured colleges and major cities.

Usage:
  python tools/enrich_college_images.py --limit 2000
  python tools/enrich_college_images.py --featured-only
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CREDS = ROOT / "android" / "tools" / "serviceAccount.json"

WIKI_API = "https://commons.wikimedia.org/w/api.php"
USER_AGENT = "CollegeRealityIndia/1.0 (education app; contact: admin@collegereality.in)"


def get_db(creds_path: Path, project: str):
    import firebase_admin
    from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(creds_path)),
        {"projectId": project},
    )
    return firestore.client()


def wiki_search_image(query: str) -> str | None:
    params = urllib.parse.urlencode({
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": f"{query} college campus building india",
        "gsrnamespace": "6",
        "gsrlimit": "3",
        "prop": "imageinfo",
        "iiprop": "url",
        "iiurlwidth": "800",
    })
    req = urllib.request.Request(f"{WIKI_API}?{params}", headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception:  # noqa: BLE001
        return None

    pages = (data.get("query") or {}).get("pages") or {}
    for page in pages.values():
        infos = page.get("imageinfo") or []
        if not infos:
            continue
        url = infos[0].get("thumburl") or infos[0].get("url")
        if url and url.startswith("https://"):
            return url
    return None


def clean_search_name(name: str) -> str:
    name = re.sub(r"\b(college|institute|university|of|the|and)\b", "", name, flags=re.I)
    return re.sub(r"\s+", " ", name).strip()[:60]


def enrich_college(data: dict, college_id: str) -> dict | None:
    cover = data.get("coverPhotoUrl")
    logo = data.get("logoUrl")
    if cover and logo:
        return None

    name = data.get("name") or ""
    city = data.get("city") or ""
    state = data.get("state") or ""
    if len(name) < 5:
        return None

    query = clean_search_name(f"{name} {city} {state}")
    patch: dict = {"updatedAt": datetime.now(timezone.utc).isoformat()}

    if not cover:
        img = wiki_search_image(query)
        if img:
            patch["coverPhotoUrl"] = img
            photos = list(data.get("photoUrls") or [])
            if img not in photos:
                photos.insert(0, img)
            patch["photoUrls"] = photos[:5]

    if not logo and patch.get("coverPhotoUrl"):
        patch["logoUrl"] = patch["coverPhotoUrl"]

    return patch if len(patch) > 1 else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(DEFAULT_CREDS))
    parser.add_argument("--project", default="college-reality")
    parser.add_argument("--limit", type=int, default=1500, help="Max colleges to enrich")
    parser.add_argument("--featured-only", action="store_true")
    parser.add_argument("--delay", type=float, default=0.3, help="Seconds between API calls")
    args = parser.parse_args()

    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"Credentials not found: {creds_path}", file=sys.stderr)
        return 1

    db = get_db(creds_path, args.project)

    candidates: list[tuple] = []
    for doc in db.collection("colleges").where("isActive", "==", True).stream():
        data = doc.to_dict() or {}
        if data.get("coverPhotoUrl"):
            continue
        if args.featured_only and not data.get("isFeatured"):
            continue
        priority = 0
        if data.get("isFeatured"):
            priority += 10
        if data.get("category") in {"Engineering", "Medical", "MBA"}:
            priority += 5
        if data.get("type") in {"government", "deemed", "autonomous"}:
            priority += 3
        candidates.append((priority, doc.id, data))

    candidates.sort(key=lambda x: -x[0])
    candidates = candidates[: args.limit]

    print(f"Enriching images for {len(candidates)} colleges...")
    enriched = 0
    batch = db.batch()
    n = 0

    for _, doc_id, data in candidates:
        patch = enrich_college(data, doc_id)
        time.sleep(args.delay)
        if not patch:
            continue
        batch.update(db.collection("colleges").document(doc_id), patch)
        n += 1
        enriched += 1
        if n >= 100:
            batch.commit()
            batch = db.batch()
            n = 0
            print(f"  Enriched {enriched}...")
        if enriched >= args.limit:
            break

    if n:
        batch.commit()

    print(f"Done. Enriched {enriched} colleges with Wikimedia images.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
