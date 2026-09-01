#!/usr/bin/env python3
"""Stage 1 of 2: find candidate campus photos for colleges via Wikipedia's
official search API + Wikimedia Commons image licenses -- NOT a scraper.
Writes a review CSV; nothing is downloaded here. See
tools/download_reviewed_college_photos.py for stage 2.

Why this exists instead of Google Images / Unsplash: scraping Google's
search results violates their Terms of Service (and is unreliable --
results are JS-rendered); Unsplash returns unrelated generic stock
photos for a specific named institution, not an actual photo of it. This
script only ever uses Wikimedia's own public, documented, ToS-sanctioned
API, matching the same source this codebase already hand-picked 9 real
campus photos from (lib/core/utils/college_image_helper.dart).

REALISTIC COVERAGE: sampled live -- 0/8 random colleges from this
45,020-college bulk-imported dataset have ANY Wikipedia article at all.
Coverage exists mainly for prominent institutions (IITs, NITs, central/
major state universities, AIIMS, etc), likely a few hundred total, not
thousands. This script will correctly find nothing for the long tail --
that's not a bug, it reflects that no legitimate photo source exists
for most of these small/district colleges.

Matching a college name to a Wikipedia article is fuzzy by nature --
review the output CSV yourself (sorted worst-confidence-first) before
running stage 2. A wrong match would attach a photo of the WRONG
institution to a college.

LICENSING: Commons images carry their own license (CC-BY, CC-BY-SA,
public domain, etc) -- this script records the license name in the CSV,
but does not automate in-app attribution. If a license requires
attribution and you display these images publicly, you're responsible
for adding that -- check the `license` column before using a photo.

Usage:
    pip install firebase-admin --break-system-packages
    python tools/find_college_wikipedia_photos.py                      # all colleges
    python tools/find_college_wikipedia_photos.py --limit 200            # test on a subset
    python tools/find_college_wikipedia_photos.py --resume               # skip IDs already in the output CSV
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
DEFAULT_OUTPUT = ROOT / "tools" / "college_photo_candidates.csv"

WIKI_API = "https://en.wikipedia.org/w/api.php"
# Wikimedia's own API etiquette (https://meta.wikimedia.org/wiki/User-Agent_policy)
# requires a descriptive User-Agent identifying the tool -- not spoofing a
# browser. maxlag politely backs off automatically if Wikipedia's own
# servers are under load, instead of hammering them.
USER_AGENT = "CollegeRealityIndia-PhotoLookup/1.0 (one-time bulk lookup tool; not deployed automatically)"
REQUEST_DELAY_SECONDS = 0.5
MAXLAG = 5

# Wikipedia/Commons housekeeping images that are never a real campus photo
# -- logos, seals, maps, generic site icons, etc. Filtered by filename
# substring, case-insensitive.
_NON_PHOTO_PATTERNS = re.compile(
    r"(logo|seal|crest|coat.?of.?arms|emblem|icon|map_|_map\.|flag_of|"
    r"commons-logo|wiki_letter|question_book|edit-icon|ambox|folder|"
    r"symbol|signature|stub|disambig|wiktionary|nuvola|padlock|"
    r"portrait|headshot|official.?photograph|profile.?pic)",
    re.IGNORECASE,
)
_NON_PHOTO_EXTENSIONS = {".svg", ".gif", ".ico"}

# A person's name as a filename (e.g. "Parag Agrawal in 2005.jpg",
# "K. Sivan.jpg") -- an article about a college often has portrait photos
# of notable alumni/officials mixed in with real campus photos, and a
# person's name doesn't otherwise look like a housekeeping file, so it
# needs its own check. Deliberately conservative (2-4 capitalized words,
# optionally with a trailing "in <year>") to avoid also rejecting
# legitimate multi-word building names -- this is a heuristic, not
# perfect, which is exactly why the CSV this produces is meant to be
# reviewed by a human, not trusted blindly.
_LIKELY_PERSON_NAME = re.compile(
    r"^File:[A-Z][a-zA-Z.]*(\s+[A-Z][a-zA-Z.]*){1,3}(\s+in\s+\d{4})?\.(jpg|jpeg|png)$",
    re.IGNORECASE,
)


def api_get(params: dict) -> dict:
    params = {**params, "format": "json", "maxlag": MAXLAG}
    url = f"{WIKI_API}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    max_attempts = 5
    for attempt in range(max_attempts):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            # 503 = maxlag backoff signal; 429 = rate-limited. Both mean
            # "you're going too fast, wait and retry", not "give up" --
            # a long bulk run WILL hit this eventually even at a polite
            # request rate, so retrying (rather than failing that college
            # outright, as an earlier version of this script did) matters.
            if e.code in (503, 429) and attempt < max_attempts - 1:
                retry_after = e.headers.get("Retry-After") if e.headers else None
                delay = float(retry_after) if retry_after else 3 * (2 ** attempt)
                print(f"    (HTTP {e.code}, backing off {delay:.0f}s before retry {attempt + 2}/{max_attempts})")
                time.sleep(delay)
                continue
            raise
    raise RuntimeError("Wikipedia API request failed after retries")


def similarity(a: str, b: str) -> float:
    return SequenceMatcher(None, a.lower().strip(), b.lower().strip()).ratio()


def search_best_title(college_name: str) -> tuple[str, float] | None:
    """Returns (matched Wikipedia article title, name-similarity score) or
    None if nothing plausible turned up.

    Trusts Wikipedia's OWN search relevance ranking (its first result) --
    re-ranking by a crude string-similarity metric was tried first and
    caught picking "List of IIT Bombay people" over the actual "Indian
    Institute of Technology Bombay" article, since a list-page title can
    have higher raw character overlap with a query than the real article's
    full official name. Wikipedia's relevance ranking uses far more
    signal than that. The similarity score is still computed and returned
    -- purely as a confidence flag for the review CSV, never for picking
    which result to use.
    """
    data = api_get({
        "action": "query", "list": "search",
        "srsearch": college_name, "srlimit": 3,
    })
    results = data.get("query", {}).get("search", [])
    if not results:
        return None
    top = results[0]
    return top["title"], round(similarity(college_name, top["title"]), 3)


def candidate_photos_for_title(title: str, top_n: int = 3) -> list[dict]:
    """Fetches every image on the article, filters out non-photo
    housekeeping images and likely person portraits (see
    _LIKELY_PERSON_NAME's comment -- an article about a college commonly
    also has photos of notable alumni/officials mixed in), returns up to
    top_n candidates sorted largest-first (a reasonable proxy for "actual
    photo" vs "small inline icon", but not infallible -- that's why
    multiple candidates are returned instead of silently trusting #1).
    `redirects=1` matters here: a search result's title is often itself a
    redirect (e.g. "Indian Institute of Technology Bombay" -> "IIT
    Bombay"), and without following it this query returns zero images."""
    data = api_get({
        "action": "query", "titles": title,
        "generator": "images", "gimlimit": 50, "redirects": 1,
        "prop": "imageinfo", "iiprop": "url|mime|size|extmetadata",
    })
    pages = data.get("query", {}).get("pages", {})
    candidates = []
    for page in pages.values():
        filename = page.get("title", "")
        if any(filename.lower().endswith(ext) for ext in _NON_PHOTO_EXTENSIONS):
            continue
        if _NON_PHOTO_PATTERNS.search(filename):
            continue
        if _LIKELY_PERSON_NAME.match(filename):
            continue
        for info in page.get("imageinfo", []):
            if not info.get("mime", "").startswith("image/"):
                continue
            width = info.get("width", 0)
            height = info.get("height", 0)
            if width < 300 or height < 200:  # too small to be a real cover photo
                continue
            meta = info.get("extmetadata", {})
            license_name = meta.get("LicenseShortName", {}).get("value", "unknown")
            candidates.append({
                "filename": filename,
                "url": info.get("url"),
                "width": width,
                "height": height,
                "license": license_name,
            })
    candidates.sort(key=lambda c: c["width"] * c["height"], reverse=True)
    return candidates[:top_n]


def load_colleges(limit: int | None) -> list[tuple[str, str]]:
    import firebase_admin
    from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(credentials.Certificate(str(CREDS)), {"projectId": "college-reality"})
    db = firestore.client()

    colleges = []
    query = db.collection("colleges")
    if limit:
        query = query.limit(limit)
    for snap in query.stream():
        data = snap.to_dict() or {}
        name = data.get("name")
        if name:
            colleges.append((snap.id, name))
    return colleges


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--limit", type=int, default=None, help="Only process the first N colleges (for testing).")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help=f"Output CSV path (default: {DEFAULT_OUTPUT})")
    parser.add_argument("--resume", action="store_true", help="Skip college IDs already present in the output CSV.")
    args = parser.parse_args()

    if not CREDS.exists():
        raise SystemExit(f"Missing service account key at {CREDS}")

    output_path = Path(args.output)
    already_done: set[str] = set()
    if args.resume and output_path.exists():
        with open(output_path, newline="", encoding="utf-8") as f:
            already_done = {row["college_id"] for row in csv.DictReader(f)}
        print(f"Resuming -- {len(already_done)} college(s) already in {output_path}, will skip them.")

    print("Loading colleges from Firestore...")
    colleges = load_colleges(args.limit)
    print(f"Loaded {len(colleges)} college(s).\n")

    # image_url/image_filename is the auto-picked best guess (largest
    # surviving candidate after filtering) -- review it using
    # image_filename before trusting it, and check candidate_2/3 as
    # alternatives if it looks wrong (a building name is a good sign; a
    # person's name or anything unclear is not, and the row should be
    # fixed or deleted before stage 2 runs).
    fieldnames = [
        "college_id", "college_name", "matched_wikipedia_title", "name_similarity",
        "wikipedia_url", "image_url", "image_filename", "image_width", "image_height", "license",
        "candidate_2_url", "candidate_2_filename",
        "candidate_3_url", "candidate_3_filename",
    ]
    file_exists = output_path.exists() and args.resume
    mode = "a" if file_exists else "w"
    with open(output_path, mode, newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not file_exists:
            writer.writeheader()

        found = 0
        for i, (college_id, name) in enumerate(colleges, start=1):
            if college_id in already_done:
                continue
            try:
                match = search_best_title(name)
                time.sleep(REQUEST_DELAY_SECONDS)
                if match is None:
                    continue
                title, sim = match
                photos = candidate_photos_for_title(title)
                time.sleep(REQUEST_DELAY_SECONDS)
                if not photos:
                    continue
            except Exception as e:
                print(f"[{i}/{len(colleges)}] {college_id}: ERROR -- {e}")
                continue

            wiki_url = f"https://en.wikipedia.org/wiki/{urllib.parse.quote(title.replace(' ', '_'))}"
            row = {
                "college_id": college_id,
                "college_name": name,
                "matched_wikipedia_title": title,
                "name_similarity": sim,
                "wikipedia_url": wiki_url,
                "image_url": photos[0]["url"],
                "image_filename": photos[0]["filename"],
                "image_width": photos[0]["width"],
                "image_height": photos[0]["height"],
                "license": photos[0]["license"],
            }
            if len(photos) > 1:
                row["candidate_2_url"] = photos[1]["url"]
                row["candidate_2_filename"] = photos[1]["filename"]
            if len(photos) > 2:
                row["candidate_3_url"] = photos[2]["url"]
                row["candidate_3_filename"] = photos[2]["filename"]
            writer.writerow(row)
            f.flush()
            found += 1
            flag = "" if sim >= 0.8 else "  <-- LOW CONFIDENCE, check this one"
            print(
                f"[{i}/{len(colleges)}] {college_id}: matched {title!r} "
                f"(similarity={sim}), top image={photos[0]['filename']!r}{flag}"
            )

    print(f"\n{found} candidate(s) written to {output_path}")
    print(
        "\nNEXT STEP: open that CSV and review every row yourself before running stage 2:\n"
        "  - Check image_filename looks like a building/campus, not a person's name or\n"
        "    something unrelated -- if candidate_2/3_filename looks more right, copy that\n"
        "    URL into image_url instead.\n"
        "  - Rows with name_similarity below ~0.8 matched a Wikipedia article whose title\n"
        "    isn't very close to the college's name -- double-check wikipedia_url is\n"
        "    actually the right institution before trusting the row.\n"
        "  - Delete any row you don't trust.\n"
        "Then run tools/download_reviewed_college_photos.py on the file you've reviewed."
    )


if __name__ == "__main__":
    main()
