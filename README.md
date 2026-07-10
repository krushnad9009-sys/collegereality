# 🎓 College Reality

> **Know the Reality Before You Take Admission**

India's best college review platform built with Flutter. Get authentic reviews from real students before making your admission decision.

## 🚀 Quick Links

- **[Getting Started Guide](./GETTING_STARTED.md)** - Start here!
- **[Firebase Setup](./FIREBASE_SETUP.md)** - Step-by-step Firebase configuration
- **[Complete Setup Guide](./SETUP.md)** - Detailed setup instructions
- **[Phase 1 Summary](./PHASE1_SUMMARY.md)** - Features & architecture overview

## ✨ Features (Phase 1 MVP)

### ✅ Authentication
- Email/Password signup & login
- Google Sign-In integration
- Form validation with 8+ validators
- Secure password requirements
- Error handling with user feedback

### ✅ User Management
- Firestore user profiles
- Profile updates & avatars
- Email verification ready
- Phone verification ready
- User role support (student/admin)

### ✅ Beautiful UI
- Material 3 design system
- Light & dark mode support
- Responsive layouts (mobile/tablet/web)
- Smooth animations & transitions
- Professional typography (Poppins)

### ✅ Navigation
- Route-based navigation (GoRouter)
- Auth-aware redirects
- Proper state management (Riverpod)
- Deep linking ready

### ✅ Reusable Components
- Custom buttons (primary, secondary, social)
- Advanced text fields with validation
- Dialog helpers (error, success, confirm)
- Loading indicators
- Snackbar notifications

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Windows Desktop
- ✅ macOS Desktop
- ✅ Linux Desktop

## 🛠️ Technology Stack

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Flutter | 3.12.2+ |
| Language | Dart | 3.12.2+ |
| State Management | Riverpod | 2.5.1 |
| Navigation | GoRouter | 14.2.0 |
| Backend | Firebase | Latest |
| Design | Material 3 | Latest |
| Fonts | Google Fonts | 6.2.1 |

## 📦 Installation

### Prerequisites
```bash
# Check Flutter version
flutter --version  # Should be 3.12.2 or higher
```

### Setup
```bash
# Clone repository
git clone https://github.com/krushnad9009-sys/collegereality.git
cd collegereality

# Get dependencies
flutter pub get

# Configure Firebase (REQUIRED - see FIREBASE_SETUP.md)
# Update lib/firebase_options.dart with your credentials

# Run the app
flutter run
```

## 🔧 Firebase Configuration

**This is REQUIRED before running the app.**

Follow the step-by-step guide in **[FIREBASE_SETUP.md](./FIREBASE_SETUP.md)** to:
1. Create a Firebase project
2. Register your apps (Android/iOS/Web)
3. Download configuration files
4. Update firebase_options.dart
5. Deploy Firestore security rules

## 📁 Project Structure

```
lib/
├── config/
│   ├── router/          # Navigation (GoRouter)
│   └── theme/           # Material 3 theme
├── core/
│   ├── services/        # Firebase auth wrapper
│   └── widgets/         # Reusable UI components
├── features/
│   ├── auth/            # Authentication module
│   │   ├── models/      # User model
│   │   ├── providers/   # Riverpod state
│   │   ├── services/    # Firestore ops
│   │   ├── screens/     # Auth screens
│   │   └── utils/       # Validators
│   └── home/            # Home module
│       ├── screens/     # Dashboard
│       └── widgets/     # Components
├── firebase_options.dart # Firebase config
└── main.dart            # App entry point
```

## 🎯 Architecture

Built with **Clean Architecture** principles:
- **Models**: Data representation
- **Repositories**: Data access layer
- **Services**: Business logic
- **Providers**: State management (Riverpod)
- **Screens/Widgets**: UI layer

## 🚀 Getting Started

1. **[Read this first: GETTING_STARTED.md](./GETTING_STARTED.md)**
2. **Configure Firebase**: Follow [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)
3. **Run the app**: `flutter run`
4. **Test the flow**: Signup → Dashboard

## 📊 Current Status

| Module | Status | Version |
|--------|--------|---------|
| Phase 1 MVP | ✅ Complete | 1.0.0 |
| Splash Screen | ✅ Complete | 1.0 |
| Onboarding | ✅ Complete | 1.0 |
| Authentication | ✅ Complete | 1.0 |
| Home Dashboard | ✅ Complete | 1.0 |
| UI Components | ✅ Complete | 1.0 |
| Firebase | 🔧 Needs Config | - |

## 🗺️ Roadmap

### Phase 2 (Next)
- [ ] College Search (by city/state)
- [ ] College Listing with filters
- [ ] College Details page
- [ ] Reviews & Rating system
- [ ] Student Profile management
- [ ] Favorites

### Phase 3 (Future)
- [ ] Admin Dashboard (Flutter Web)
- [ ] Placements tracking
- [ ] Analytics
- [ ] Push Notifications
- [ ] College Comparison

## 🧪 Testing

```bash
# Run tests
flutter test

# Analyze code quality
flutter analyze

# Format code
dart format lib/
```

## 🐛 Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Firebase Issues
- See [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) for common issues
- Check Firebase Console for logs
- Verify google-services.json / GoogleService-Info.plist

### Android Issues
- Ensure google-services.json is in android/app/
- Update SHA-1 certificate in Firebase Console
- Check Android SDK version

### iOS Issues
- Open ios/Runner.xcworkspace (not .xcodeproj)
- Ensure GoogleService-Info.plist is added to Xcode
- Update iOS deployment target in Xcode

## 📚 Documentation

- **[GETTING_STARTED.md](./GETTING_STARTED.md)** - Quick start guide
- **[FIREBASE_SETUP.md](./FIREBASE_SETUP.md)** - Firebase configuration
- **[SETUP.md](./SETUP.md)** - Complete setup guide
- **[PHASE1_SUMMARY.md](./PHASE1_SUMMARY.md)** - Feature overview

## 🔐 Security

- ✅ Firebase security rules configured
- ✅ Email validation implemented
- ✅ Strong password requirements
- ✅ User data isolation
- ✅ Admin role support
- ✅ Phone verification ready

## 📄 Code Quality

- Follows Dart linting rules
- Clean Architecture principles
- SOLID principles applied
- DRY code (Don't Repeat Yourself)
- Comprehensive error handling
- Well-documented code

## 🚀 Deployment

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Then upload via Xcode/TestFlight
```

### Web
```bash
flutter build web --release
# Deploy the build/web folder
```

## 📞 Support

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

## 📝 License

Proprietary and Confidential - College Reality Platform

---

## 🎉 Ready to Get Started?

1. **First**: Read [GETTING_STARTED.md](./GETTING_STARTED.md)
2. **Then**: Follow [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)
3. **Finally**: Run `flutter run`

**Happy coding! 🚀**

---

**Version**: 1.0.0 (Phase 1 MVP)  
**Last Updated**: 2026-07-10  
**Status**: Production Ready ✓
