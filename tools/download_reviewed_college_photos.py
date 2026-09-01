#!/usr/bin/env python3
"""Stage 2 of 2: downloads the photos YOU'VE reviewed and kept in the CSV
produced by tools/find_college_wikipedia_photos.py, saving each as
./college_photos/<college_id>.jpg -- ready for
tools/update_college_cover_photos.py.

Does not do any matching/searching itself -- it trusts the CSV exactly
as given, so review that file first. Delete any row you don't want
downloaded before running this.

Usage:
    pip install requests
    # optional, for real JPEG re-encoding of non-JPEG Commons files:
    pip install pillow
    python tools/download_reviewed_college_photos.py                 # dry run (default)
    python tools/download_reviewed_college_photos.py --apply          # actually download
"""
from __future__ import annotations

import argparse
import csv
import io
import time
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = ROOT / "tools" / "college_photo_candidates.csv"
DEFAULT_OUTPUT_DIR = ROOT / "college_photos"
USER_AGENT = "CollegeRealityIndia-PhotoDownload/1.0 (one-time bulk download tool)"
REQUEST_DELAY_SECONDS = 0.2

try:
    from PIL import Image
    HAVE_PILLOW = True
except ImportError:
    HAVE_PILLOW = False


def save_as_jpeg(content: bytes, dest: Path) -> None:
    if HAVE_PILLOW:
        img = Image.open(io.BytesIO(content))
        if img.mode in ("RGBA", "P", "LA"):
            img = img.convert("RGB")
        img.save(dest, "JPEG", quality=85)
    else:
        # No Pillow -- save the raw bytes as-is with a .jpg extension.
        # Works fine in practice (browsers/Flutter's image decoders sniff
        # actual format from content, not the extension), but the file
        # may not literally be JPEG-encoded internally if Commons served
        # a PNG. Install pillow for a real conversion.
        dest.write_bytes(content)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input", default=str(DEFAULT_INPUT), help=f"Reviewed CSV from stage 1 (default: {DEFAULT_INPUT})")
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR), help=f"Where to save photos (default: {DEFAULT_OUTPUT_DIR})")
    parser.add_argument("--apply", action="store_true", help="Actually download. Without this flag, runs as a dry run.")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(
            f"Input CSV not found: {input_path}\n"
            "Run tools/find_college_wikipedia_photos.py first, review its output, then point --input at it."
        )

    output_dir = Path(args.output_dir)
    if not HAVE_PILLOW:
        print("NOTE: Pillow isn't installed -- files will be saved as-is, not re-encoded to real JPEG.")
        print("      pip install pillow for a proper conversion.\n")

    with open(input_path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"[{mode}] {len(rows)} row(s) in {input_path}\n")

    if args.apply:
        output_dir.mkdir(parents=True, exist_ok=True)

    downloaded = 0
    failed = 0
    for i, row in enumerate(rows, start=1):
        college_id = row["college_id"]
        url = row["image_url"]
        dest = output_dir / f"{college_id}.jpg"

        if not args.apply:
            print(f"[{i}/{len(rows)}] {college_id}: would download {url}")
            continue

        try:
            resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=20)
            resp.raise_for_status()
            save_as_jpeg(resp.content, dest)
            print(f"[{i}/{len(rows)}] {college_id}: saved -> {dest}")
            downloaded += 1
        except Exception as e:
            print(f"[{i}/{len(rows)}] {college_id}: FAILED -- {e}")
            failed += 1
        time.sleep(REQUEST_DELAY_SECONDS)

    print("\n--- Summary ---")
    print(f"Rows in CSV: {len(rows)}")
    if args.apply:
        print(f"Downloaded: {downloaded}")
        print(f"Failed:     {failed}")
        print(f"\nNext step: python tools/update_college_cover_photos.py --apply")
    else:
        print("\nDry run only -- no files downloaded. Re-run with --apply to download for real.")


if __name__ == "__main__":
    main()
