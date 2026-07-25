# College Reality — Super Admin Web Panel

Separate Flutter Web entry point for super administrators only.

## Run locally

```bash
flutter run -t lib/admin/main_admin.dart -d chrome
```

## Build for deployment

```bash
flutter build web -t lib/admin/main_admin.dart --release
```

## Access requirements

1. Firebase Auth email/password account
2. Firestore `users/{uid}.userType` must be exactly `super_admin`
3. Admin and moderator accounts are denied at login and on every route

## Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```
