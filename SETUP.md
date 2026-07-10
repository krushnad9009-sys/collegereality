# College Reality - Setup Guide

## Phase 1 Implementation Complete ✓

This document provides setup instructions for the College Reality Flutter application.

## Prerequisites

- Flutter SDK 3.12.2 or higher
- Dart 3.12.2 or higher
- Firebase account
- Git

## Installation Steps

### 1. Clone & Setup

```bash
# Clone the repository
git clone https://github.com/krushnad9009-sys/collegereality.git
cd collegereality

# Install dependencies
flutter pub get

# Clean build
flutter clean
flutter pub get
```

### 2. Firebase Setup (Required)

#### 2.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named "college-reality"
3. Enable the following services:
   - **Authentication** (Email, Google Sign-In)
   - **Cloud Firestore** (Database)
   - **Cloud Storage** (for images)
   - **Cloud Messaging** (for notifications)

#### 2.2 Android Configuration

1. In Firebase Console, register Android app:
   - Package name: `com.collegereality.app`
   - SHA-1 certificate fingerprint:
     ```bash
     # Get SHA-1 from:
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

2. Download `google-services.json` and place it at:
   ```
   android/app/google-services.json
   ```

3. Configure Android build:
   - Update `android/build.gradle`
   - Update `android/app/build.gradle`

#### 2.3 iOS Configuration

1. In Firebase Console, register iOS app:
   - Bundle ID: `com.collegereality.app`

2. Download `GoogleService-Info.plist` and add it to Xcode:
   - Open `ios/Runner.xcworkspace`
   - Drag `GoogleService-Info.plist` to Runner project
   - Select "Copy items if needed"

#### 2.4 Web Configuration

1. In Firebase Console, register Web app
2. Copy the Firebase config
3. Update `lib/firebase_options.dart` with Web config

#### 2.5 Update firebase_options.dart

Edit `lib/firebase_options.dart` with your actual Firebase credentials:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'college-reality',
  authDomain: 'college-reality.firebaseapp.com',
  storageBucket: 'college-reality.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'college-reality',
  storageBucket: 'college-reality.appspot.com',
);

// Similar for iOS, macOS, and Windows
```

### 3. Firestore Security Rules (Development)

In Firebase Console, go to Firestore Database > Rules and set:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    // Colleges collection
    match /colleges/{collegeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth.uid == resource.data.userId || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
  }
}
```

### 4. Run the Application

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Build Web
flutter build web
```

## Project Structure

```
lib/
├── config/
│   ├── router/          # GoRouter configuration
│   └── theme/           # Material 3 theme
├── core/
│   ├── services/        # Core services (auth, etc.)
│   └── widgets/         # Reusable widgets
├── features/
│   ├── auth/            # Authentication module
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── utils/
│   │   └── widgets/
│   └── home/            # Home module
│       ├── screens/
│       ├── widgets/
│       └── providers/
├── firebase_options.dart
└── main.dart
```

## Phase 1 Features Implemented

### ✅ Splash Screen
- Beautiful animated splash screen
- Auto-navigation based on auth state

### ✅ Onboarding
- 4-step onboarding flow
- Material 3 design with gradients
- Smooth page transitions
- Skip functionality

### ✅ Authentication
- Email/Password signup and login
- Google Sign-In integration
- Form validation with custom validators
- Error handling and user feedback
- Persistent session management

### ✅ Firestore Integration
- User model with JSON serialization
- Automatic user document creation
- User profile updates
- Email/Phone verification

### ✅ Home Dashboard
- User greeting with profile avatar
- Quick access shortcuts (By City, By State, Top Rated, Trending)
- Featured colleges section (sample data)
- Call-to-action for writing reviews
- Profile menu with options

### ✅ Reusable Components
- Custom buttons (Primary, Secondary, Google Sign-In, Social)
- Custom text fields (Email, Password, Phone with country code)
- Dialog helpers (Error, Success, Confirm)
- Snackbar helpers (Error, Success, Info)
- Loading indicators

## Next Steps (Phase 2)

- [ ] College Listing & Search
- [ ] City-wise & State-wise Search
- [ ] College Details Page
- [ ] Reviews & Ratings System
- [ ] Student Profile Management
- [ ] Placements Information
- [ ] Fees & Courses Info
- [ ] Hostel Details
- [ ] Scholarships
- [ ] Notifications (FCM)

## Environment Variables

Create a `.env` file (not included in repo):

```env
# Firebase Config
FIREBASE_PROJECT_ID=college-reality
FIREBASE_API_KEY=your_key_here
```

## Troubleshooting

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
flutter pub downgrade  # if needed

# Check analysis
flutter analyze
```

### Firebase Connection Issues

1. Verify `google-services.json` is in `android/app/`
2. Check `GoogleService-Info.plist` is added to Xcode project
3. Verify Firebase credentials in `firebase_options.dart`
4. Check Firebase console for app registration

### Authentication Issues

1. Enable Email/Password provider in Firebase Console
2. Enable Google Sign-In provider
3. Configure OAuth consent screen
4. Add sign-in URIs if needed

## Development Notes

- Uses **GoRouter** for navigation with proper auth redirects
- Uses **Riverpod** for state management
- Uses **Material 3** design system with custom colors
- Implements **Clean Architecture** with repositories
- Uses **Firebase Auth** + **Firestore** for backend
- Responsive UI that works on mobile, tablet, and web

## Code Generation (Optional)

To regenerate JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Performance Optimization

- Image caching with `cached_network_image`
- Lazy loading for lists
- Efficient state management with Riverpod
- Code splitting with features
- Tree shaking for production builds

## Testing

```bash
# Run tests
flutter test

# Coverage
flutter test --coverage
```

## Deployment

### Android Production

```bash
flutter build apk --release
# Or for split APK
flutter build appbundle --release
```

### iOS Production

```bash
flutter build ios --release
# Then use Xcode to upload to App Store
```

### Web Production

```bash
flutter build web --release
# Deploy the build/web folder to your hosting
```

## Support & Documentation

- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Riverpod Documentation](https://riverpod.dev)

## Contributing

When adding new features:

1. Follow Clean Architecture principles
2. Create separate feature modules
3. Use Riverpod for state management
4. Write comprehensive comments
5. Test authentication flows
6. Ensure responsive design
7. Maintain Material 3 design consistency

## License

This project is proprietary and confidential.

---

**Last Updated**: 2026-07-10
**Version**: 1.0.0 - Phase 1 MVP
