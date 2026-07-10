# Firebase Configuration - Step by Step Guide

This guide will help you set up Firebase for College Reality application.

## ⚠️ IMPORTANT: This Must Be Done First

Without Firebase configuration, the app will not work. Follow these steps carefully.

---

## Step 1: Create Firebase Project

1. Visit [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Project name: **`college-reality`**
4. Click **"Create project"**
5. Wait for project creation to complete

---

## Step 2: Enable Required Services

### 2.1 Authentication
1. In Firebase Console, click **"Authentication"** (left sidebar)
2. Click **"Get Started"**
3. Enable these methods:
   - **Email/Password**: Click "Email/Password" → Enable → Save
   - **Google**: Click "Google" → Enable
     - Project support email: (select your email)
     - Project public-facing name: College Reality
     - Save

### 2.2 Cloud Firestore
1. Click **"Firestore Database"** (left sidebar)
2. Click **"Create database"**
3. Start in **"Production mode"**
4. Location: **`us-central1`** (or closest to your users)
5. Click **"Create"**
6. Go to **"Rules"** tab
7. Paste the security rules (see section below)
8. Click **"Publish"**

### 2.3 Cloud Storage
1. Click **"Storage"** (left sidebar)
2. Click **"Get Started"**
3. Click **"Start in production mode"**
4. Location: **`us-central1`**
5. Click **"Create"**

### 2.4 Cloud Messaging
1. Click **"Messaging"** (left sidebar)
2. Click **"Get Started"**
3. (No additional setup needed for now)

---

## Step 3: Register Your Apps

### 3.1 Android App Registration

1. In Firebase Console, click the **gear icon** (Settings)
2. Go to **"Project settings"**
3. Click **"Your apps"** section
4. Click **"+" button**, select **"Android"**
5. Enter details:
   - **Android package name**: `com.collegereality.app`
   - **App nickname**: College Reality (optional)
   - **Debug signing certificate SHA-1**: (follow steps below)
6. Click **"Register app"**
7. Download **`google-services.json`**
8. Place it in: **`android/app/google-services.json`**

**To get SHA-1 certificate:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line with `SHA1:` and copy the value after it.

### 3.2 iOS App Registration

1. In Firebase Console, click **"+" button**, select **"iOS"**
2. Enter details:
   - **iOS Bundle ID**: `com.collegereality.app`
   - **App nickname**: College Reality (optional)
   - **App Store ID**: (leave blank for now)
3. Click **"Register app"**
4. Download **`GoogleService-Info.plist`**
5. Add to Xcode project:
   - Open `ios/Runner.xcworkspace` (NOT .xcodeproj)
   - Drag `GoogleService-Info.plist` into Runner project
   - Check "Copy items if needed"
   - Check "Runner" target

### 3.3 Web App Registration

1. Click **"+" button**, select **"Web"**
2. App nickname: **`College Reality Web`**
3. Click **"Register app"**
4. Copy the Firebase config object (you'll need this next)

---

## Step 4: Update Firebase Configuration

### 4.1 Get Your Firebase Credentials

From Firebase Console:
1. Go to **Project Settings** (gear icon)
2. Scroll to **"Your apps"** section
3. Click on **Web** app
4. Copy the config object that looks like:
```javascript
{
  apiKey: "AIzaSy...",
  authDomain: "college-reality.firebaseapp.com",
  projectId: "college-reality",
  storageBucket: "college-reality.appspot.com",
  messagingSenderId: "123...",
  appId: "1:123...",
  measurementId: "G-..."
}
```

### 4.2 Update `lib/firebase_options.dart`

Open `lib/firebase_options.dart` and update with your credentials:

```dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // This will automatically select based on platform
    return web; // for web
  }

  // WEB CONFIGURATION
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY', // from Firebase config
    appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'college-reality',
    authDomain: 'college-reality.firebaseapp.com',
    storageBucket: 'college-reality.appspot.com',
    measurementId: 'G-MEASUREMENT_ID', // optional
  );

  // ANDROID CONFIGURATION
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );

  // iOS CONFIGURATION
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_iOS_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );

  // macOS CONFIGURATION
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_macOS_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:macos:YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );

  // WINDOWS CONFIGURATION
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:windows:YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );
}
```

**Where to find each value in Firebase Console:**

- **apiKey**: Project Settings → Web → SDK setup → config → apiKey
- **appId**: Project Settings → Web → SDK setup → config → appId
- **messagingSenderId**: Project Settings → General → Messaging sender ID
- **projectId**: Project Settings → General → Project ID
- **authDomain**: `[project-id].firebaseapp.com`
- **storageBucket**: `[project-id].appspot.com`

---

## Step 5: Configure Firestore Security Rules

In Firebase Console:

1. Go to **Firestore Database**
2. Click **"Rules"** tab
3. Replace the default rules with:

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth != null; // Logged-in users can read any profile
    }
    
    // Colleges collection - public read, admin write
    match /colleges/{collegeId} {
      allow read: if request.auth != null; // Only logged-in users can view
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if request.auth != null; // Logged-in users can read reviews
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid; // Users can create their own
      allow update, delete: if request.auth.uid == resource.data.userId || 
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin'; // Own or admin
    }
    
    // Allow deny all by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click **"Publish"**

---

## Step 6: Verify Setup

### Test Authentication

1. In Firebase Console, go to **Authentication**
2. Go to **"Users"** tab
3. Click **"Create user"** (optional - for testing)
4. Add test user:
   - Email: `test@example.com`
   - Password: `TestPassword123!`

### Test Firestore Connection

1. In Firebase Console, go to **Firestore Database**
2. Click **"Start collection"**
3. Create test collection:
   - Collection ID: `users`
   - Document ID: Auto-generate
   - Add field:
     - Field: `uid`
     - Type: `string`
     - Value: `test123`

---

## Step 7: Run the Application

Now you can run the app:

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Or on web
flutter run -d chrome
```

---

## ✅ Verification Checklist

- [ ] Firebase project created
- [ ] Authentication enabled (Email/Password + Google)
- [ ] Firestore Database created
- [ ] Cloud Storage created
- [ ] Android app registered
- [ ] iOS app registered (if developing for iOS)
- [ ] Web app registered
- [ ] `google-services.json` placed in `android/app/`
- [ ] `GoogleService-Info.plist` added to Xcode (if iOS)
- [ ] `firebase_options.dart` updated with credentials
- [ ] Firestore security rules published
- [ ] Test user created (optional)

---

## 🐛 Troubleshooting

### "Android app not registered"
→ Register Android app in Firebase Console first

### "google-services.json not found"
→ Place file at `android/app/google-services.json` (not `android/app/app/`)

### "GoogleService-Info.plist not found"
→ Add it to Xcode project (drag and drop, check "Copy items if needed")

### "Authentication not working"
→ Go to Authentication → Email/Password → Enable

### "Google Sign-In fails"
→ Go to Authentication → Google → Enable
→ Configure OAuth consent screen
→ Add signing certificate SHA-1 for Android

### "Firestore rules error"
→ Check rules are published (click "Publish")
→ Verify user is authenticated
→ Check Firestore emulator logs

### "Build errors after setup"
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

---

## 🔒 Security Notes

1. **Never commit** `google-services.json` to public repos
2. **Never share** API keys
3. **Use security rules** to restrict data access
4. **Enable** 2FA on Firebase account
5. **Review** Firestore rules before production
6. **Set up** billing alerts in Firebase Console

---

## 📞 Need Help?

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Console Help](https://support.google.com/firebase)
- [Stack Overflow Firebase Tag](https://stackoverflow.com/questions/tagged/firebase)

---

**Status**: Firebase Setup Guide v1.0  
**Last Updated**: 2026-07-10
