#!/usr/bin/env python3
"""One-time/repeatable bulk update: set `coverPhotoUrl` on `colleges`
Firestore documents from local photo files, using the app's EXISTING
schema and Storage layout -- no new fields, no parallel data model.

How matching works
-------------------
Firestore document IDs in this collection are the AISHE dataset IDs
(e.g. `aishe_1000`), not slugs or random auto-IDs -- confirmed by
sampling live data before writing this script. For every `<id>.jpg` in
--photos-dir, if a `colleges/<id>` document exists, the photo is
uploaded to Firebase Storage at `college_covers/<id>` (a public-read,
admin-only-write path added specifically for this -- see
storage.rules) and that document's `coverPhotoUrl` is set to the
resulting download URL.

Colleges with NO matching local photo are deliberately left untouched.
The app already renders a unique per-college gradient + initials
fallback when `coverPhotoUrl` is empty (see
lib/core/widgets/branded_campus_fallback.dart and
lib/core/utils/college_image_helper.dart's `resolveCoverUrl` doc
comment: "so BrandedCampusFallback renders a unique premium placeholder
per college"). Writing one shared stock-photo URL into ~44,000
documents would replace that with a single repeated image -- a visual
regression, not an improvement. If you deliberately want a shared
placeholder later, set DEFAULT_IMAGE_URL below and pass --apply-default;
that path is intentionally separate and off by default.

Naturally scoped to "however many real photos you actually have" --
there's no reliable rank/"top N" field to sort by in this bulk-imported
dataset (crScore/isFeatured are unpopulated across it), so rather than
guess a cutoff, this script simply processes every local file that has
one, whether that's 1,000 or 100.

Usage:
    pip install firebase-admin --break-system-packages
    python tools/update_college_cover_photos.py                    # dry run (default)
    python tools/update_college_cover_photos.py --apply             # actually upload + write
    python tools/update_college_cover_photos.py --photos-dir X --apply
"""
from __future__ import annotations

import argparse
import mimetypes
import re
import uuid
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"
DEFAULT_PHOTOS_DIR = ROOT / "college_photos"
STORAGE_BUCKET = "college-reality.firebasestorage.app"
STORAGE_PREFIX = "college_covers"  # matches storage.rules' college_covers/{collegeId}
BATCH_SIZE = 500  # Firestore's own hard cap on writes per batch

# Intentionally unset -- see module docstring. Only used if --apply-default
# is passed alongside a real value here.
DEFAULT_IMAGE_URL: str | None = None

# Firestore document IDs are alphanumeric/underscore/hyphen (aishe_1000 etc)
# -- reject anything else so a stray file (aishe_1000 (1).jpg, .DS_Store
# renamed to .jpg, etc.) can never be silently misread as a doc ID.
VALID_ID = re.compile(r"^[A-Za-z0-9_-]+$")


def build_download_url(blob_name: str, token: str) -> str:
    """Same {alt=media&token=...} URL shape Firebase's client-side
    getDownloadURL() produces, so this is indistinguishable from any other
    image URL the app already stores -- no special-casing needed anywhere
    downstream (CachedNetworkImage, resolveCoverUrl, etc.)."""
    encoded_path = quote(blob_name, safe="")
    return f"https://firebasestorage.googleapis.com/v0/b/{STORAGE_BUCKET}/o/{encoded_path}?alt=media&token={token}"


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--apply", action="store_true",
        help="Actually upload photos and write Firestore updates. Without this flag, runs as a dry run.",
    )
    parser.add_argument(
        "--photos-dir", default=str(DEFAULT_PHOTOS_DIR),
        help=f"Local folder of <collegeId>.jpg files (default: {DEFAULT_PHOTOS_DIR})",
    )
    parser.add_argument(
        "--apply-default", action="store_true",
        help="Also write DEFAULT_IMAGE_URL (must be set in this file) to every college that "
             "has no local photo. Off by default -- see module docstring for why.",
    )
    args = parser.parse_args()

    if args.apply_default and not DEFAULT_IMAGE_URL:
        raise SystemExit("--apply-default was passed but DEFAULT_IMAGE_URL is not set in this file.")

    if not CREDS.exists():
        raise SystemExit(
            f"Missing service account key at {CREDS}\n"
            "Download it from Firebase Console > Project Settings > Service Accounts."
        )

    photos_dir = Path(args.photos_dir)
    if not photos_dir.exists():
        raise SystemExit(f"Photos folder not found: {photos_dir}")

    import firebase_admin
    from firebase_admin import credentials, firestore, storage

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(CREDS)),
        {"projectId": "college-reality", "storageBucket": STORAGE_BUCKET},
    )
    db = firestore.client()
    bucket = storage.bucket()
    colleges = db.collection("colleges")

    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"[{mode}] Scanning {photos_dir} for <collegeId>.jpg files...\n")

    all_jpgs = sorted(photos_dir.glob("*.jpg"))
    photo_files = [p for p in all_jpgs if VALID_ID.match(p.stem)]
    skipped_names = [p.name for p in all_jpgs if not VALID_ID.match(p.stem)]

    if skipped_names:
        print(f"Skipping {len(skipped_names)} file(s) whose name isn't a plausible Firestore doc ID:")
        for name in skipped_names[:10]:
            print(f"  - {name}")
        if len(skipped_names) > 10:
            print(f"  ... and {len(skipped_names) - 10} more")
        print()

    print(f"Found {len(photo_files)} candidate photo(s) to process.\n")

    def new_batch():
        return db.batch()

    batch = new_batch()
    pending = 0
    updated = 0
    missing_doc = 0
    failed = 0
    batches_committed = 0
    updated_at_iso = None  # set once we know we have at least one write

    def flush():
        nonlocal batch, pending, batches_committed
        if pending == 0:
            return
        if args.apply:
            batch.commit()
        batches_committed += 1
        batch = new_batch()
        pending = 0

    from datetime import datetime, timezone
    updated_at_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]

    for i, photo_path in enumerate(photo_files, start=1):
        college_id = photo_path.stem
        doc_ref = colleges.document(college_id)

        try:
            snap = doc_ref.get()
        except Exception as e:
            print(f"[{i}/{len(photo_files)}] {college_id}: FAILED to read Firestore doc -- {e}")
            failed += 1
            continue

        if not snap.exists:
            print(f"[{i}/{len(photo_files)}] {college_id}: no matching colleges/{college_id} document -- skipped")
            missing_doc += 1
            continue

        blob_path = f"{STORAGE_PREFIX}/{college_id}"
        content_type = mimetypes.guess_type(photo_path.name)[0] or "image/jpeg"
        token = str(uuid.uuid4())
        download_url = build_download_url(blob_path, token)

        if args.apply:
            try:
                blob = bucket.blob(blob_path)
                # Setting this exact metadata key is what makes the URL
                # above (alt=media&token=...) actually resolve -- it's the
                # same mechanism the Firebase client SDKs use, just done
                # server-side here instead of via getDownloadURL().
                blob.metadata = {"firebaseStorageDownloadTokens": token}
                blob.upload_from_filename(str(photo_path), content_type=content_type)
            except Exception as e:
                print(f"[{i}/{len(photo_files)}] {college_id}: FAILED to upload photo -- {e}")
                failed += 1
                continue

        verb = "uploaded + queued Firestore update for" if args.apply else "would upload + update"
        print(f"[{i}/{len(photo_files)}] {college_id}: {verb}")

        batch.update(doc_ref, {
            "coverPhotoUrl": download_url,
            # A plain ISO string, NOT firestore.SERVER_TIMESTAMP -- this
            # collection's Dart model (CollegeModel.fromJson) reads
            # updatedAt via DateTime.tryParse(json['updatedAt'].toString()),
            # which silently fails (returns null) on a raw Firestore
            # Timestamp object. Matches the same fix already applied to a
            # different collection earlier for the identical reason.
            "updatedAt": updated_at_iso,
        })
        pending += 1
        updated += 1

        if pending >= BATCH_SIZE:
            flush()

    flush()

    print("\n--- Summary ---")
    print(f"Candidate photo files:           {len(photo_files)}")
    print(f"Updated (or would update):       {updated}")
    print(f"No matching Firestore document:  {missing_doc}")
    print(f"Upload/read failures:            {failed}")
    if args.apply:
        print(f"Firestore batches committed:     {batches_committed}")

    if args.apply_default and DEFAULT_IMAGE_URL:
        print(f"\n[{mode}] Applying DEFAULT_IMAGE_URL to every college with no coverPhotoUrl set...")
        no_photo_query = colleges.where("coverPhotoUrl", "==", None)
        default_batch = new_batch()
        default_pending = 0
        default_updated = 0
        for snap in no_photo_query.stream():
            default_batch.update(snap.reference, {
                "coverPhotoUrl": DEFAULT_IMAGE_URL,
                "updatedAt": updated_at_iso,
            })
            default_pending += 1
            default_updated += 1
            if default_pending >= BATCH_SIZE:
                if args.apply:
                    default_batch.commit()
                default_batch = new_batch()
                default_pending = 0
        if default_pending > 0 and args.apply:
            default_batch.commit()
        print(f"Colleges given the default image: {default_updated}")

    if not args.apply:
        print("\nDry run only -- no upload or write performed. Re-run with --apply to write for real.")


if __name__ == "__main__":
    main()
