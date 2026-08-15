#!/usr/bin/env python3
"""Enrich REAL, verified college photos/logos from Wikipedia (not raw Commons
keyword search — see rationale below).

Why this replaces a plain Commons search:
  The previous enrich_college_images.py did a free-text Commons search for
  "<name> college campus building india" and took the first hit. For the
  ~45k mostly non-notable AISHE colleges that returns either nothing, or a
  loosely related/wrong image — an unacceptable "random image" risk.

This script instead:
  1. Looks up each candidate college by name on Wikipedia's opensearch API.
  2. Requires the matched article title to share a real distinctive-token
     overlap with the college's own name (so "St. Xavier's College" doesn't
     match an unrelated "St. Xavier's Church" or similarly-named entity).
  3. Requires the article's own description/extract to contain an
     institution keyword (college/university/institute/polytechnic/IIT/
     NIT/AIIMS/academy/vidyalaya/...), rejecting disambiguation pages,
     people, places, etc.
  4. Only then pulls that specific article's lead image (Wikipedia's own
     infobox/pageimage) as coverPhotoUrl/logoUrl — never a generic search
     thumbnail for an unrelated subject.
  5. Skips (does not fabricate) anything that fails these gates. Missing
     image stays missing; the app's existing branded placeholder covers it.

Resumable/idempotent:
  - Never touches colleges that already have a coverPhotoUrl.
  - Writes a checkpoint (tools/data/image_enrichment_checkpoint.json) of
    every collegeId it has ever attempted (success AND confirmed-no-match)
    so reruns never re-spend Wikipedia calls or Firestore reads/writes on
    the same college, and can be safely stopped/resumed at any time.
  - Firestore writes are `update`s on existing documents only — never
    creates a new college document, so it cannot create duplicates.

Usage:
  python tools/enrich_college_images_verified.py --target 700 --report
  python tools/enrich_college_images_verified.py --target 700 --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
CHECKPOINT_PATH = ROOT / "tools" / "data" / "image_enrichment_checkpoint.json"
REPORT_PATH = ROOT / "tools" / "data" / "image_enrichment_report.json"

WIKI_OPENSEARCH = "https://en.wikipedia.org/w/api.php"
WIKI_SUMMARY = "https://en.wikipedia.org/api/rest_v1/page/summary/{}"
USER_AGENT = "CollegeRealityIndia/1.0 (education app; contact: admin@collegereality.in)"

INSTITUTION_KEYWORDS = (
    "college", "university", "institute", "polytechnic", "vidyalaya",
    "academy", "iit", "nit", "iiit", "aiims", "school of", "vidyapeeth",
    "mahavidyalaya", "engineering college", "medical college", "law college",
)
STOPWORDS = {
    "college", "institute", "university", "of", "the", "and", "for",
    "technology", "engineering", "science", "sciences", "campus", "india",
    "a", "an", "in", "at", "affiliated", "autonomous", "govt", "government",
}


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


def _http_json(url: str) -> dict | None:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:  # noqa: BLE001
        return None


def significant_tokens(text: str) -> set[str]:
    words = re.findall(r"[a-zA-Z]{3,}", text.lower())
    return {w for w in words if w not in STOPWORDS}


def opensearch_titles(query: str) -> list[str]:
    params = urllib.parse.urlencode({
        "action": "opensearch",
        "search": query,
        "limit": "3",
        "namespace": "0",
        "format": "json",
    })
    data = _http_json(f"{WIKI_OPENSEARCH}?{params}")
    if not data or len(data) < 2:
        return []
    return data[1] or []


def name_match_score(college_name: str, article_title: str) -> float:
    college_tokens = significant_tokens(college_name)
    title_tokens = significant_tokens(article_title)
    if not college_tokens or not title_tokens:
        return 0.0
    overlap = college_tokens & title_tokens
    return len(overlap) / max(1, len(college_tokens))


def _location_tokens(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-zA-Z]{3,}", text.lower())}


def title_location_conflicts(article_title: str, city: str, district: str, state: str) -> bool:
    """True if the article title carries an explicit place-name disambiguator
    (e.g. "Government Medical College, Thiruvananthapuram") that does NOT
    match this college's own city/district/state. Indian government college
    names repeat across many cities/states ("Government Medical College",
    "Government Arts College", "Government College for Women", ...) and
    Wikipedia disambiguates same-named institutions by appending the actual
    city — a title-token match alone is not enough to prove it's the same
    college, so a conflicting disambiguator is a hard rejection.
    """
    if "," not in article_title:
        return False
    suffix = article_title.split(",", 1)[1]
    suffix_tokens = _location_tokens(suffix)
    if not suffix_tokens:
        return False
    known_tokens = _location_tokens(f"{city} {district} {state}")
    return suffix_tokens.isdisjoint(known_tokens)


def find_verified_image(name: str, city: str, state: str, district: str = "") -> dict | None:
    """Returns {"title", "image", "score"} for a high-confidence match, or None."""
    for query in (f"{name} {city}", f"{name}"):
        titles = opensearch_titles(query)
        for title in titles:
            score = name_match_score(name, title)
            if score < 0.6:
                continue
            if title_location_conflicts(title, city, district, state):
                continue
            summary = _http_json(WIKI_SUMMARY.format(urllib.parse.quote(title)))
            if not summary:
                continue
            if summary.get("type") == "disambiguation":
                continue
            desc = f"{summary.get('description', '')} {summary.get('extract', '')}".lower()
            if not any(kw in desc for kw in INSTITUTION_KEYWORDS):
                continue
            # A generic Indian institution name ("Government Medical College",
            # "Government Arts College", etc, with no distinctive proper noun)
            # needs the city to show up somewhere in the matched title or
            # extract — otherwise we cannot tell which city's homonymous
            # college this article is actually about.
            is_generic = len(significant_tokens(name) - {"government", "govt"}) <= 3
            if is_generic and city:
                city_tokens = _location_tokens(city)
                haystack = _location_tokens(f"{title} {desc}")
                if city_tokens and city_tokens.isdisjoint(haystack):
                    continue
            image = (
                (summary.get("originalimage") or {}).get("source")
                or (summary.get("thumbnail") or {}).get("source")
            )
            if not image or not image.startswith("https://"):
                continue
            return {"title": title, "image": image, "score": round(score, 2)}
    return None


def load_checkpoint() -> dict:
    if CHECKPOINT_PATH.exists():
        return json.loads(CHECKPOINT_PATH.read_text(encoding="utf-8"))
    return {"attempted": {}}


def save_checkpoint(cp: dict) -> None:
    CHECKPOINT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CHECKPOINT_PATH.write_text(json.dumps(cp, indent=2, ensure_ascii=False), encoding="utf-8")


CANDIDATE_CACHE_PATH = ROOT / "tools" / "data" / "image_candidate_cache.json"


def _load_candidate_cache() -> dict[str, dict]:
    if CANDIDATE_CACHE_PATH.exists():
        try:
            return json.loads(CANDIDATE_CACHE_PATH.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            return {}
    return {}


def _save_candidate_cache(cache: dict[str, dict]) -> None:
    CANDIDATE_CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CANDIDATE_CACHE_PATH.write_text(
        json.dumps(cache, indent=2, ensure_ascii=False), encoding="utf-8"
    )


def fetch_candidates(
    db, cap: int, sub_cap: int | None = None, prefer_cache: bool = True,
) -> list[tuple[int, str, dict]]:
    """Candidate colleges lacking an image, ranked by notability priority.

    Backed by a local on-disk cache (image_candidate_cache.json) so repeated
    enrichment runs/passes do NOT repeatedly re-scan the Firestore
    collection — this was the single biggest source of daily read-quota
    exhaustion before caching was added. Only hits Firestore when the cache
    doesn't yet have enough usable (still imageless) entries.
    """
    cache = _load_candidate_cache()
    if prefer_cache and cache:
        usable = [
            (0, cid, data) for cid, data in cache.items()
            if not data.get("coverPhotoUrl")
        ]
        if len(usable) >= cap or len(usable) >= 2000:
            # Re-derive priority the same way live-fetched candidates would.
            ranked = []
            for _, cid, data in usable:
                priority = 8 if data.get("type") in ("government", "deemed", "autonomous") else 1
                if data.get("isFeatured"):
                    priority += 10
                ranked.append((priority, cid, data))
            ranked.sort(key=lambda x: -x[0])
            print(f"  (using {len(ranked)} candidates from local cache — no Firestore reads)")
            return ranked[:cap]

    fresh = _fetch_candidates_from_firestore(db, cap, sub_cap)
    for priority, cid, data in fresh:
        cache[cid] = data
    _save_candidate_cache(cache)
    return fresh


def _fetch_candidates_from_firestore(
    db, cap: int, sub_cap: int | None = None,
) -> list[tuple[int, str, dict]]:
    """Server-side filtered candidate pull — never scans the full 45k collection."""
    seen: dict[str, dict] = {}

    def add(query, priority_base):
        try:
            stream = query.stream()
            for doc in stream:
                if doc.id in seen:
                    continue
                data = doc.to_dict() or {}
                if data.get("coverPhotoUrl"):
                    continue
                priority = priority_base
                if data.get("isFeatured"):
                    priority += 10
                seen[doc.id] = (priority, doc.id, data)
        except Exception as e:  # noqa: BLE001 - transient network/stream errors
            print(f"  (candidate fetch interrupted early: {e}; using {len(seen)} gathered so far)")

    # Cap each individual stream well under the point where this
    # environment's gRPC connection tends to hit a ping timeout on a long
    # continuous stream; re-running (or a later pass with a larger sub_cap)
    # accretes more via the checkpoint.
    sub_cap = min(cap, sub_cap or 1500)

    colleges = db.collection("colleges")
    add(colleges.where("isFeatured", "==", True).where("isActive", "==", True), 20)
    add(colleges.where("type", "==", "government").where("isActive", "==", True).limit(sub_cap), 8)
    add(colleges.where("type", "==", "deemed").where("isActive", "==", True).limit(sub_cap), 8)
    add(colleges.where("type", "==", "autonomous").where("isActive", "==", True).limit(sub_cap), 8)
    # Government-run institutions in these categories are disproportionately
    # likely to be old, notable, and have an actual Wikipedia article
    # (unlike most of the ~45k small private AISHE-only colleges).
    for category, priority in (
        ("Medical", 4), ("Engineering", 3), ("Law", 3), ("Arts", 2),
        ("Commerce", 2), ("Science", 2), ("Nursing", 2), ("Pharmacy", 2),
        ("Polytechnic", 2), ("Agriculture", 2),
    ):
        if len(seen) >= cap:
            break
        add(
            colleges.where("category", "==", category)
            .where("type", "in", ["government", "deemed", "autonomous"])
            .where("isActive", "==", True)
            .limit(sub_cap),
            priority,
        )

    # Government/deemed/autonomous pools above are small (~4k total) and get
    # exhausted after a few runs. Private colleges are ~41k and mostly
    # obscure, but a meaningful minority (established engineering/medical/
    # management institutes — VIT, SRM, Manipal-style names, etc.) are
    # genuinely Wikipedia-notable. Lower priority than the government tier
    # since the hit rate here is lower, but it's what keeps a long-running
    # background pass finding new real matches instead of re-scanning an
    # already-exhausted pool.
    for category, priority in (
        ("Engineering", 1), ("MBA", 1), ("Medical", 1), ("Pharmacy", 1),
        ("Law", 1), ("Nursing", 1), ("Arts", 1), ("Commerce", 1),
    ):
        if len(seen) >= cap:
            break
        add(
            colleges.where("category", "==", category)
            .where("type", "==", "private")
            .where("isActive", "==", True)
            .limit(sub_cap),
            priority,
        )

    ranked = sorted(seen.values(), key=lambda x: -x[0])
    return ranked


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(DEFAULT_CREDS))
    parser.add_argument("--project", default="college-reality")
    parser.add_argument("--target", type=int, default=700, help="Successful enrichments to reach")
    parser.add_argument(
        "--candidate-cap", type=int, default=20000,
        help="Overall per-pass ceiling on gathered candidates (safety limit, not a query limit)",
    )
    parser.add_argument("--delay", type=float, default=0.15)
    parser.add_argument(
        "--workers", type=int, default=16,
        help="Concurrent Wikipedia lookup workers (network-bound, not CPU-bound)",
    )
    parser.add_argument(
        "--checkpoint-every", type=int, default=20,
        help="Save the checkpoint file every N candidates processed (crash/interrupt safety)",
    )
    parser.add_argument(
        "--continuous", action="store_true",
        help="Keep running successive passes with a widening candidate pool "
             "until --target is hit, the pool is exhausted, or --max-minutes elapses.",
    )
    parser.add_argument(
        "--max-minutes", type=float, default=180,
        help="Wall-clock budget for --continuous mode before stopping gracefully.",
    )
    parser.add_argument(
        "--max-candidate-cap", type=int, default=20000,
        help="Ceiling the per-subquery limit escalates to across --continuous passes.",
    )
    parser.add_argument("--dry-run", action="store_true", help="No Firestore writes")
    parser.add_argument("--report", action="store_true", help="Write verification report JSON")
    args = parser.parse_args()

    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"Credentials not found: {creds_path}", file=sys.stderr)
        return 1

    db = get_db(creds_path, args.project)
    checkpoint = load_checkpoint()
    attempted = checkpoint["attempted"]

    deadline = time.monotonic() + args.max_minutes * 60
    sub_cap = args.candidate_cap
    pass_num = 0

    while True:
        pass_num += 1
        total_successes = run_pass(db, checkpoint, args, sub_cap=sub_cap, pass_num=pass_num)
        if total_successes >= args.target:
            print(f"Reached target of {args.target} verified enrichments.")
            break
        if not args.continuous:
            break
        if time.monotonic() >= deadline:
            print(f"Stopping: --max-minutes={args.max_minutes} budget reached "
                  f"(total so far: {total_successes}).")
            break
        if sub_cap >= args.max_candidate_cap:
            print(f"Stopping: candidate pool exhausted at cap={sub_cap} "
                  f"(total so far: {total_successes}).")
            break
        sub_cap = min(sub_cap * 2, args.max_candidate_cap)
        print(f"Pass {pass_num} done. Widening candidate pool to {sub_cap} for pass {pass_num + 1}...")

    if args.report:
        write_report(checkpoint, args)

    return 0


def run_pass(db, checkpoint: dict, args, *, sub_cap: int, pass_num: int) -> int:
    """One fetch+enrich pass. Returns the running total of real enrichments."""
    attempted = checkpoint["attempted"]

    already_enriched_this_run = sum(
        1 for v in attempted.values() if v.get("status") == "enriched"
    )
    print(f"[pass {pass_num}] Checkpoint has {already_enriched_this_run} enrichments so far "
          f"(candidate sub_cap={sub_cap}).")

    candidates = fetch_candidates(db, args.candidate_cap, sub_cap=sub_cap)
    print(f"[pass {pass_num}] Fetched {len(candidates)} candidate colleges (server-side filtered).")

    def _is_final(status: str | None) -> bool:
        # dry_run_preview is intentionally NOT final — it never wrote
        # anything to Firestore, so a real run must still be free to pick
        # that college up and actually enrich it.
        return status is not None and status != "dry_run_preview"

    pending = [
        (doc_id, data) for _, doc_id, data in candidates
        if not _is_final((attempted.get(doc_id) or {}).get("status"))
    ]
    print(f"{len(pending)} not yet attempted (checkpoint already covers the rest).")

    enriched_this_run: list[dict] = []
    batch = db.batch()
    n_in_batch = 0
    total_successes = already_enriched_this_run
    processed_since_checkpoint = 0
    used_images: set[str] = {
        v["image"] for v in attempted.values()
        if v.get("status") == "enriched" and v.get("image")
    }

    def lookup(item):
        doc_id, data = item
        name = data.get("name") or ""
        city = data.get("city") or ""
        state = data.get("state") or ""
        district = data.get("district") or ""
        if len(name) < 5:
            return doc_id, data, None, "skipped_short_name"
        match = find_verified_image(name, city, state, district)
        return doc_id, data, match, None

    # Network-bound Wikipedia lookups dominate wall time (~2-4 HTTP round
    # trips per candidate); a thread pool keeps this feasible for thousands
    # of candidates instead of one HTTP round trip at a time.
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(lookup, item): item for item in pending}
        for future in as_completed(futures):
            if total_successes >= args.target:
                break
            doc_id, data, match, skip_reason = future.result()
            if _is_final((attempted.get(doc_id) or {}).get("status")):
                continue  # defensive: shouldn't happen, pending was pre-filtered

            processed_since_checkpoint += 1
            name = data.get("name") or ""
            city = data.get("city") or ""
            state = data.get("state") or ""

            if skip_reason:
                attempted[doc_id] = {"status": skip_reason}
            elif not match:
                attempted[doc_id] = {"status": "no_verified_match"}
            elif match["image"] in used_images:
                # Same image already claimed by a different college this run
                # — almost always a shared template/logo bleeding through a
                # bad match, never a legitimate duplicate.
                attempted[doc_id] = {
                    "status": "rejected_duplicate_image",
                    "wouldHaveMatched": match["title"],
                }
            else:
                used_images.add(match["image"])
                patch = {
                    "coverPhotoUrl": match["image"],
                    "logoUrl": match["image"],
                    "photoUrls": [match["image"]],
                    "updatedAt": datetime.now(timezone.utc).isoformat(),
                    "imageSource": f"wikipedia:{match['title']}",
                }
                record = {
                    "id": doc_id,
                    "name": name,
                    "city": city,
                    "state": state,
                    "matchedArticle": match["title"],
                    "matchScore": match["score"],
                    "image": match["image"],
                }
                if not args.dry_run:
                    batch.update(db.collection("colleges").document(doc_id), patch)
                    n_in_batch += 1
                    if n_in_batch >= 50:
                        batch.commit()
                        batch = db.batch()
                        n_in_batch = 0
                if args.dry_run:
                    # Do not let a dry-run "would have matched" claim block a
                    # future real run from actually writing this college —
                    # only a run that truly wrote to Firestore may mark a
                    # college as done.
                    attempted[doc_id] = {"status": "dry_run_preview", **record}
                else:
                    attempted[doc_id] = {"status": "enriched", **record}
                enriched_this_run.append(record)
                total_successes += 1
                if total_successes % 25 == 0:
                    print(f"  ...{total_successes}/{args.target} verified images so far")

            if processed_since_checkpoint >= args.checkpoint_every:
                if n_in_batch:
                    batch.commit()
                    batch = db.batch()
                    n_in_batch = 0
                save_checkpoint(checkpoint)
                processed_since_checkpoint = 0

    if n_in_batch:
        batch.commit()

    save_checkpoint(checkpoint)

    print(f"[pass {pass_num}] Newly enriched this pass: {len(enriched_this_run)}.")
    print(f"[pass {pass_num}] Total verified-enriched to date (checkpoint): {total_successes}.")
    print(f"[pass {pass_num}] Candidates checked, no confident match: "
          f"{sum(1 for v in attempted.values() if v.get('status') == 'no_verified_match')}")

    return total_successes


def write_report(checkpoint: dict, args) -> None:
    attempted = checkpoint["attempted"]
    all_enriched = [v for v in attempted.values() if v.get("status") == "enriched"]
    by_state: dict[str, int] = {}
    for rec in all_enriched:
        by_state[rec.get("state", "?")] = by_state.get(rec.get("state", "?"), 0) + 1
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "totalVerifiedEnriched": len(all_enriched),
        "target": args.target,
        "byState": by_state,
        "sample": all_enriched[:25],
        "dryRun": args.dry_run,
    }
    REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Report written to {REPORT_PATH}")


if __name__ == "__main__":
    raise SystemExit(main())
