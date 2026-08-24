#!/usr/bin/env python3
"""One-time bootstrap: promote an existing Firebase Auth user to
`super_admin` using the app's EXISTING role architecture.

Context: this project's admin authorization is entirely Firestore-based --
`users/{uid}.userType` -- checked both client-side (AdminPermissions /
isSuperAdminProvider / isStaffProvider) and server-side
(firestore.rules' isAdmin()/isSuperAdmin()/isStaff() functions, which
`get()` the same field). There are no Firebase custom claims involved
anywhere in this app. A normal client can NEVER set this field on their
own account -- firestore.rules' isSafeUserCreate() forces every new
`users` doc to userType == 'student', and ownerCannotElevatePrivileges()
forces every owner-initiated update to leave userType unchanged. The only
paths that can ever change it are an existing admin's app-mediated write,
or a trusted server-side script like this one using the Admin SDK (which
bypasses security rules by design, exactly as intended for a one-time
bootstrap before any admin exists yet).

This script does NOT invent a new role system, a custom claim, or a new
Firestore collection -- it sets the one field
(`users/{uid}.userType = 'super_admin'`) the existing architecture already
reads everywhere.

Usage:
    pip install firebase-admin --break-system-packages
    python tools/set_super_admin.py you@example.com              # dry run (default)
    python tools/set_super_admin.py you@example.com --apply       # actually write
"""
from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CREDS = ROOT / "android" / "tools" / "serviceAccount.json"

SUPER_ADMIN_USER_TYPE = "super_admin"  # RoleConstants.userTypeSuperAdmin


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("email", help="Email of the existing Firebase Auth user to promote.")
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually write to Firestore. Without this flag, runs as a dry run.",
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
    from firebase_admin import auth, credentials, firestore

    if firebase_admin._apps:
        firebase_admin.delete_app(firebase_admin.get_app())
    firebase_admin.initialize_app(
        credentials.Certificate(str(CREDS)),
        {"projectId": "college-reality"},
    )
    db = firestore.client()

    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"[{mode}] Resolving Firebase Auth user for {args.email} ...", flush=True)

    try:
        auth_user = auth.get_user_by_email(args.email)
    except auth.UserNotFoundError:
        raise SystemExit(
            f"No Firebase Authentication user exists for {args.email}. "
            f"Sign up / sign in with that email in the app first."
        )

    uid = auth_user.uid
    print(f"  Found Auth user: uid={uid} email={auth_user.email} "
          f"emailVerified={auth_user.email_verified} disabled={auth_user.disabled}")

    user_ref = db.collection("users").document(uid)
    snap = user_ref.get()

    if not snap.exists:
        raise SystemExit(
            f"No users/{uid} Firestore profile document exists yet for this "
            f"account. This app creates that document the first time you "
            f"complete sign-in/profile setup in the regular student app "
            f"(flutter run -t lib/main.dart) -- do that once, then re-run "
            f"this script. (Deliberately not fabricating a profile document "
            f"here: the regular signup path sets several other fields this "
            f"script shouldn't have to guess at or duplicate.)"
        )

    data = snap.to_dict() or {}
    current_type = data.get("userType")
    print(f"  Current users/{uid}.userType = {current_type!r}")

    if current_type == SUPER_ADMIN_USER_TYPE:
        print(f"  Already {SUPER_ADMIN_USER_TYPE} -- nothing to do.")
        return

    print(f"  Will set users/{uid}.userType = {SUPER_ADMIN_USER_TYPE!r} "
          f"(all other fields left untouched).")

    if not args.apply:
        print("\nDry run only -- no write performed. Re-run with --apply to write for real.")
        return

    user_ref.set(
        {
            "userType": SUPER_ADMIN_USER_TYPE,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    print(f"\nDone. users/{uid}.userType is now '{SUPER_ADMIN_USER_TYPE}'.")
    print(
        "Sign out and back in (or hard-refresh) in "
        "'flutter run -t lib/admin/main_admin.dart -d chrome' for the change "
        "to take effect -- isSuperAdminProvider re-reads this doc on auth "
        "state change, but an already-open session won't re-fetch it "
        "automatically."
    )


if __name__ == "__main__":
    main()
