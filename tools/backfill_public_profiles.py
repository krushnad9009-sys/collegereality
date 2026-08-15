#!/usr/bin/env python3
"""One-time backfill: create public_profiles/{uid} mirror docs for every
existing `users` document, stripping email/phone.

Context: firestore.rules now only lets the owner/staff read a `users` doc
(it holds email/phone). Any other viewer (guide directory, connectable
students, call setup) reads the new public_profiles/{uid} mirror instead.
The app writes that mirror going forward on every profile update, but
users who haven't touched their profile since this deploy won't have a
mirror doc yet and will silently drop out of guide/connectable-student
discovery until they do. Run this once against production to backfill
everyone immediately.

Read of `users` + write of `public_profiles` only — never modifies or
deletes anything in `users`. Safe to re-run (idempotent merge writes).

Usage:
    pip install firebase-admin --break-system-packages
    python tools/backfill_public_profiles.py            # dry run (default)
    python tools/backfill_public_profiles.py --apply     # actually write
"""
from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"

# Keep in sync with FirestoreUserService.syncPublicProfile's strip list.
STRIP_FIELDS = {"email", "phone"}


def build_public_profile(user_data: dict) -> dict:
    return {k: v for k, v in user_data.items() if k not in STRIP_FIELDS}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually write to Firestore. Without this flag, runs as a dry run.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=400,
        help="Firestore batch write size (max 500). Default 400.",
    )
    args = parser.parse_args()

    if not CREDS.exists():
        raise SystemExit(
            f"Missing service account key at {CREDS}\n"
            f"Copy tools/serviceAccount.example.json to that path and fill in "
            f"real credentials from Firebase Console > Project Settings > "
            f"Service Accounts."
        )

    import firebase_admin
    from firebase_admin import credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(CREDS)),
        {"projectId": "college-reality"},
    )
    db = firestore.client()

    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"[{mode}] Backfilling public_profiles from users ...", flush=True)

    total = 0
    written = 0
    skipped_no_id = 0
    batch = db.batch()
    batch_count = 0

    for doc in db.collection("users").stream():
        total += 1
        uid = doc.id
        data = doc.to_dict() or {}
        if not uid:
            skipped_no_id += 1
            continue

        public_data = build_public_profile(data)
        if not public_data:
            continue

        if args.apply:
            ref = db.collection("public_profiles").document(uid)
            batch.set(ref, public_data, merge=True)
            batch_count += 1
            if batch_count >= args.batch_size:
                batch.commit()
                batch = db.batch()
                batch_count = 0
        written += 1

        if total % 500 == 0:
            print(f"  processed {total} users ...", flush=True)

    if args.apply and batch_count > 0:
        batch.commit()

    print(f"Done. users scanned={total} public_profiles written={written} "
          f"skipped(no id)={skipped_no_id}")
    if not args.apply:
        print("This was a dry run — re-run with --apply to write to Firestore.")


if __name__ == "__main__":
    main()
