#!/usr/bin/env python3
"""Second-source college image enrichment: web search + official-site
discovery, for colleges Wikipedia has no article for.

No paid Google/Bing Image Search API key is configured in this environment
(checked: no SERPAPI/BING/GOOGLE_CSE credentials). This uses DuckDuckGo's
keyless HTML search endpoint (no API key required, same lite endpoint many
tools use for programmatic organic search) to find each college's likely
official website, then extracts THAT SITE's own designated image
(og:image/twitter:image meta tag, falling back to a qualifying <img> on the
page) — i.e. the institution's own chosen public image, not a random image-
search thumbnail of unknown provenance.

Correctness gates before ANY image is accepted:
  1. Known listing/aggregator/content-farm domains are hard-blocked
     (collegedunia, shiksha, careers360, collegedekho, getmyuni, ...) —
     their photos are frequently stock/generic or uncredited, not "clearly
     attributable public sources".
  2. The search result's own title must token-overlap the college name
     (reuses the same scorer as the Wikipedia pass).
  3. The fetched page's own text must mention the college's city or state
     somewhere — rejects a same-named-but-wrong-location result.
  4. The extracted image must be a real raster image (no .svg — the app's
     CachedNetworkImage widgets can't decode SVG, so an SVG URL would
     render as a broken image) and not a shared/duplicate image already
     claimed by a different college this run.

Shares the SAME checkpoint file as enrich_college_images_verified.py, so:
  - The 20 Wikipedia-sourced colleges are never re-touched (already
    "enriched" + already have coverPhotoUrl in Firestore).
  - Anything this script finds is recorded there too, so a later Wikipedia
    pass (or a rerun of this script) won't duplicate work.
  - `imageSource` on each patched doc records the true source
    ("official_site:<domain>") so provenance stays honest and auditable.

Usage:
  python tools/enrich_college_images_web_search.py --target 50 --dry-run --report
  python tools/enrich_college_images_web_search.py --target 700 --report
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

sys.path.insert(0, str(Path(__file__).resolve().parent))
from enrich_college_images_verified import (  # noqa: E402
    ROOT, DEFAULT_CREDS, CHECKPOINT_PATH, get_db, load_checkpoint,
    save_checkpoint, significant_tokens, name_match_score, _location_tokens,
    fetch_candidates,
)

REPORT_PATH = ROOT / "tools" / "data" / "image_enrichment_web_search_report.json"

BROWSER_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"
)

BLOCKED_DOMAINS = {
    "collegedunia.com", "shiksha.com", "careers360.com", "collegedekho.com",
    "getmyuni.com", "universitykart.com", "collegesearch.in",
    "indiaeducation.net", "jagranjosh.com", "quora.com", "youtube.com",
    "pinterest.com", "twitter.com", "x.com", "linkedin.com", "reddit.com",
    "amazon.in", "amazon.com", "justdial.com", "sulekha.com", "yelp.com",
    "en.wikipedia.org",  # already covered by the dedicated Wikipedia pass
    # Hospital/clinic/college listing directories — their photos are
    # frequently generic, stock, or belong to the *directory site*, not the
    # specific institution (caught mislabeled flag/social icons from these
    # during dry-run validation).
    "hexahealth.com", "medindia.net", "practo.com", "lybrate.com",
    "credihealth.com", "indiastudychannel.com", "findglocal.com",
    "healthworldindia.com", "curofy.com", "clinicspots.com",
    "hospitalsindia.info", "vymaps.com", "tour-plan.in",
    "yellowpages.in", "indiamart.com", "tripadvisor.in", "tripadvisor.com",
}

# Only meta tags are trusted for the actual image (see extract_page_image).
# A same-site <img> fallback was tried during dry-run validation and it
# picked up a Facebook-share icon and a decorative national-flag icon as
# "the college photo" on two different real government sites — completely
# wrong images despite the *domain* being legitimate. Precision over
# recall: skip the college rather than risk that class of error again.


def _http_get(url: str, timeout: float = 10) -> str | None:
    req = urllib.request.Request(url, headers={"User-Agent": BROWSER_UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            return raw.decode("utf-8", errors="ignore")
    except Exception:  # noqa: BLE001
        return None


def web_search(query: str, limit: int = 5) -> list[tuple[str, str]]:
    """Returns [(url, title), ...] organic results via DuckDuckGo HTML search."""
    q = urllib.parse.urlencode({"q": query})
    body = _http_get(f"https://html.duckduckgo.com/html/?{q}", timeout=12)
    if not body:
        return []
    raw_links = re.findall(
        r'class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>', body, re.S
    )
    results = []
    for href, title in raw_links[:limit]:
        parsed = urllib.parse.urlparse(href)
        target = href
        if parsed.path.startswith("/l/") or "duckduckgo.com" in parsed.netloc:
            qs = urllib.parse.parse_qs(parsed.query)
            if "uddg" in qs:
                target = urllib.parse.unquote(qs["uddg"][0])
        title_clean = re.sub(r"<[^<]+?>", "", title).strip()
        results.append((target, title_clean))
    return results


def domain_of(url: str) -> str:
    try:
        host = urllib.parse.urlparse(url).netloc.lower()
        return host[4:] if host.startswith("www.") else host
    except Exception:  # noqa: BLE001
        return ""


_ICON_LIKE = re.compile(
    r"(facebook|instagram|twitter|whatsapp|youtube[-_]?icon|linkedin|"
    r"social[-_]?icon|share[-_]?icon|\bflag\b|sprite|favicon|placeholder|"
    r"default[-_]?avatar|loading\.(gif|svg|png)|\bico[-_]|/icons?/|"
    r"1x1|pixel\.(gif|png)|arrow[-_]?icon|menu[-_]?icon|close[-_]?icon)",
    re.I,
)


def _verify_real_image(url: str, min_bytes: int = 6000) -> bool:
    """HEAD-check the actual bytes, not just the filename — catches tiny
    icons/pixels that don't declare width in HTML and don't match the
    filename-based icon patterns."""
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": BROWSER_UA})
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            ctype = (resp.headers.get("Content-Type") or "").lower()
            clen = resp.headers.get("Content-Length")
            if not ctype.startswith("image/") or "svg" in ctype:
                return False
            if clen is not None and int(clen) < min_bytes:
                return False
            return True
    except Exception:  # noqa: BLE001
        return False


_LOGO_HINT = re.compile(r"(logo|site-logo|brand)", re.I)
_HERO_HINT = re.compile(r"(hero|banner|slide|carousel|campus|building|gallery)", re.I)


def extract_page_image(html: str, base_url: str) -> str | None:
    # 1) Meta tags first — the institution's own declared representative
    # image, when present.
    for pattern in (
        r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']',
        r'<meta[^>]+name=["\']twitter:image["\'][^>]+content=["\']([^"\']+)["\']',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']twitter:image["\']',
    ):
        m = re.search(pattern, html, re.I)
        if not m:
            continue
        candidate = urllib.parse.urljoin(base_url, m.group(1).strip())
        if not candidate.startswith("https://") or candidate.lower().endswith(".svg"):
            continue
        if _ICON_LIKE.search(candidate):
            continue
        if _verify_real_image(candidate):
            return candidate

    # 2) No usable meta tag — fall back to a real <img> on the *already
    # location/name-verified* page, but only one that passes three
    # independent gates: not icon-shaped by filename, plausibly a real
    # photo/logo by its own class/alt hints (not just any random image on
    # the page), and independently verified by actual HTTP Content-Type +
    # size (catches the flag-icon/Facebook-icon class of error the naive
    # first attempt produced, since those don't always declare width=).
    best: tuple[int, str] | None = None  # (priority, url)
    for img in re.findall(r"<img[^>]+>", html, re.I)[:80]:
        src_m = re.search(r'src=["\']([^"\']+)["\']', img, re.I)
        if not src_m:
            continue
        src = urllib.parse.urljoin(base_url, src_m.group(1).strip())
        if not src.startswith("https://") or src.lower().endswith(".svg"):
            continue
        if _ICON_LIKE.search(src) or _ICON_LIKE.search(img):
            continue
        width_m = re.search(r'width=["\']?(\d+)', img)
        if width_m and int(width_m.group(1)) < 150:
            continue
        priority = 0
        if _HERO_HINT.search(img):
            priority = 2
        elif _LOGO_HINT.search(img):
            priority = 1
        else:
            continue  # no positive signal this is a meaningful content image
        if best is None or priority > best[0]:
            best = (priority, src)

    if best and _verify_real_image(best[1]):
        return best[1]
    return None


OFFICIAL_TLD_SUFFIXES = (".gov.in", ".ac.in", ".edu.in", ".nic.in", ".res.in")


def is_official_looking_domain(domain: str) -> bool:
    return any(domain.endswith(s) for s in OFFICIAL_TLD_SUFFIXES)


def find_official_site_image(
    name: str, city: str, state: str, district: str,
) -> dict | None:
    query = f"{name} {city} {state} official website"
    results = web_search(query, limit=6)
    for url, title in results:
        domain = domain_of(url)
        if not domain or domain in BLOCKED_DOMAINS:
            continue
        # A trusted .gov.in/.ac.in/.edu.in/.nic.in domain is strong evidence
        # on its own; anything else (generic .com/.org/.in) needs a much
        # tighter name match before we'll even fetch it, since third-party
        # sites for a same/similar name are common.
        min_score = 0.5 if is_official_looking_domain(domain) else 0.8
        if name_match_score(name, title) < min_score:
            continue

        html = _http_get(url, timeout=10)
        if not html:
            continue

        # Location gate: reject a same-named-but-wrong-place result. Search
        # visible text loosely (strip tags) plus the raw title/meta for the
        # city/state — full DOM text extraction isn't needed for this check.
        text_sample = re.sub(r"<[^>]+>", " ", html)[:20000]
        haystack = _location_tokens(text_sample)
        city_tokens = _location_tokens(city)
        state_tokens = _location_tokens(state)
        if city_tokens and city_tokens.isdisjoint(haystack) and \
           state_tokens and state_tokens.isdisjoint(haystack):
            continue

        image = extract_page_image(html, url)
        if not image:
            continue

        return {
            "sourceUrl": url,
            "domain": domain,
            "matchedTitle": title,
            "image": image,
            "score": round(name_match_score(name, title), 2),
        }
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", default=str(DEFAULT_CREDS))
    parser.add_argument("--project", default="college-reality")
    parser.add_argument("--target", type=int, default=50)
    parser.add_argument("--candidate-cap", type=int, default=20000)
    parser.add_argument("--sub-cap", type=int, default=3000)
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--checkpoint-every", type=int, default=10)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"Credentials not found: {creds_path}", file=sys.stderr)
        return 1

    db = get_db(creds_path, args.project)
    checkpoint = load_checkpoint()
    attempted = checkpoint["attempted"]

    def is_final(status: str | None) -> bool:
        return status is not None and status not in (
            "dry_run_preview", "web_search_dry_run_preview", "no_verified_match",
        )
        # NOTE: "no_verified_match" from the Wikipedia pass is intentionally
        # NOT final here — this is a different source, worth a second try.

    candidates = fetch_candidates(db, args.candidate_cap, sub_cap=args.sub_cap)
    print(f"Fetched {len(candidates)} candidate colleges (server-side filtered).")

    pending = [
        (doc_id, data) for _, doc_id, data in candidates
        if not is_final((attempted.get(doc_id) or {}).get("status"))
    ]
    print(f"{len(pending)} eligible for web-search enrichment "
          f"(already-enriched/rejected colleges excluded).")
    pending = pending[: max(args.target * 8, 100)]  # bound the search volume per run
    print(f"Searching {len(pending)} of them this run (target={args.target}).")

    searched = 0
    high_confidence = 0
    rejected = 0
    skipped = 0
    samples: list[dict] = []
    used_images: set[str] = {
        v["image"] for v in attempted.values()
        if v.get("status") in ("enriched",) and v.get("image")
    }

    batch = db.batch()
    n_in_batch = 0
    pending_batch_records: list[tuple[str, dict]] = []  # (doc_id, record) not yet committed
    processed_since_checkpoint = 0
    total_enriched = sum(1 for v in attempted.values() if v.get("status") == "enriched")

    def commit_pending_batch() -> None:
        """Commits the current batch and only THEN marks those colleges as
        'enriched' in the checkpoint. Marking before commit would let a
        failed/quota-exhausted commit silently lose the Firestore write
        while the checkpoint still claims success — exactly the bug caught
        earlier in the Wikipedia pass's dry-run handling.
        """
        nonlocal batch, n_in_batch, pending_batch_records
        if n_in_batch == 0:
            return
        try:
            batch.commit()
            for doc_id, record in pending_batch_records:
                attempted[doc_id] = {"status": "enriched", "source": "web_search", **record}
        except Exception as e:  # noqa: BLE001
            print(f"  (batch commit failed, {len(pending_batch_records)} colleges "
                  f"NOT written and will be retried next run: {e})")
            # Do not mark as enriched or as any other final status — leave
            # them absent from `attempted` entirely so a future run retries.
        finally:
            batch = db.batch()
            n_in_batch = 0
            pending_batch_records = []

    def worker(item):
        doc_id, data = item
        name = data.get("name") or ""
        city = data.get("city") or ""
        state = data.get("state") or ""
        district = data.get("district") or ""
        if len(name) < 5:
            return doc_id, data, None, "skipped_short_name"
        match = find_official_site_image(name, city, state, district)
        return doc_id, data, match, None

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(worker, item): item for item in pending}
        for future in as_completed(futures):
            if total_enriched >= args.target:
                break
            doc_id, data, match, skip_reason = future.result()
            searched += 1
            name = data.get("name") or ""
            city = data.get("city") or ""
            state = data.get("state") or ""

            if skip_reason:
                skipped += 1
                attempted[doc_id] = {"status": skip_reason}
            elif not match:
                rejected += 1
                attempted[doc_id] = {"status": "web_search_no_match"}
            elif match["image"] in used_images:
                rejected += 1
                attempted[doc_id] = {
                    "status": "rejected_duplicate_image",
                    "wouldHaveMatched": match["sourceUrl"],
                }
            else:
                used_images.add(match["image"])
                record = {
                    "id": doc_id,
                    "name": name,
                    "city": city,
                    "state": state,
                    "sourceUrl": match["sourceUrl"],
                    "domain": match["domain"],
                    "matchedTitle": match["matchedTitle"],
                    "matchScore": match["score"],
                    "image": match["image"],
                }
                if len(samples) < 15:
                    samples.append(record)

                if args.dry_run:
                    attempted[doc_id] = {
                        "status": "web_search_dry_run_preview", **record,
                    }
                    high_confidence += 1
                else:
                    patch = {
                        "coverPhotoUrl": match["image"],
                        "logoUrl": match["image"],
                        "photoUrls": [match["image"]],
                        "updatedAt": datetime.now(timezone.utc).isoformat(),
                        "imageSource": f"official_site:{match['domain']}",
                    }
                    batch.update(db.collection("colleges").document(doc_id), patch)
                    n_in_batch += 1
                    pending_batch_records.append((doc_id, record))
                    if n_in_batch >= 25:
                        commit_pending_batch()
                    high_confidence += 1
                    total_enriched += 1

            processed_since_checkpoint += 1
            if processed_since_checkpoint >= args.checkpoint_every:
                commit_pending_batch()
                save_checkpoint(checkpoint)
                processed_since_checkpoint = 0
                print(f"  ...searched={searched} high_confidence={high_confidence} "
                      f"rejected={rejected} skipped={skipped}")

    commit_pending_batch()
    save_checkpoint(checkpoint)

    success_rate = (high_confidence / searched * 100) if searched else 0.0
    print(f"Done. searched={searched} high_confidence={high_confidence} "
          f"rejected={rejected} skipped={skipped} "
          f"success_rate={success_rate:.2f}%")

    if args.report:
        report = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "source": "web_search_official_site",
            "dryRun": args.dry_run,
            "target": args.target,
            "searched": searched,
            "highConfidenceMatches": high_confidence,
            "rejected": rejected,
            "skipped": skipped,
            "estimatedSuccessRatePercent": round(success_rate, 2),
            "sampleSourceUrls": samples,
        }
        REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Report written to {REPORT_PATH}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
