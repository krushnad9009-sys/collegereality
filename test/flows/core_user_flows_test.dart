import 'package:college_reality_india/features/admin/providers/admin_provider.dart';
import 'package:college_reality_india/features/auth/screens/login_screen.dart';
import 'package:college_reality_india/features/auth/screens/signup_screen.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:college_reality_india/features/community/screens/community_hub_screen.dart';
import 'package:college_reality_india/features/ecosystem/screens/request_college_screen.dart';
import 'package:college_reality_india/features/profile/screens/profile_screen.dart';
import 'package:college_reality_india/features/reviews/screens/write_review_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

CollegeModel _sampleCollege() {
  return CollegeModel(
    id: 'c1',
    name: 'Test Engineering College',
    nameLower: 'test engineering college',
    slug: 'c1',
    city: 'Pune',
    cityLower: 'pune',
    district: 'Pune',
    districtLower: 'pune',
    state: 'Maharashtra',
    stateLower: 'maharashtra',
    address: 'Test address',
    type: 'private',
    courses: const ['B.Tech'],
    fees: const CollegeFees(
      tuitionMin: 100000,
      tuitionMax: 200000,
      hostelAnnual: 50000,
    ),
    placements: const CollegePlacements(
      highestPackageLpa: 12,
      averagePackageLpa: 6,
      placementPercentage: 80,
    ),
    accreditation: const CollegeAccreditation(),
    aggregatedRatings: const CollegeRatings(
      overall: 4,
      teaching: 4,
      placements: 4,
      faculty: 4,
      hostel: 4,
      food: 4,
      infrastructure: 4,
      campusLife: 4,
      attendance: 4,
      sports: 4,
      fees: 4,
    ),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void _setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Login flow', () {
    testWidgets('email login navigates home', (tester) async {
      _setTallSurface(tester);
      final auth = FakeAuthService();
      await pumpRouterApp(
        tester,
        initialLocation: '/login',
        overrides: testAuthOverrides(authService: auth),
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/signup',
            builder: (_, _) => const Scaffold(body: Text('SIGNUP')),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const Scaffold(body: Text('FORGOT')),
          ),
        ],
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@test.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'College1');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(auth.signInEmailCalls, 1);
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('Signup flow', () {
    testWidgets('requires terms agreement before creating account',
        (tester) async {
      _setTallSurface(tester);
      final auth = FakeAuthService();
      final users = FakeUserRepository();
      await pumpRouterApp(
        tester,
        initialLocation: '/signup',
        overrides: testAuthOverrides(authService: auth, userRepository: users),
        routes: [
          GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('LOGIN')),
          ),
          GoRoute(
            path: '/profile/display-name-setup',
            builder: (_, _) => const Scaffold(body: Text('SETUP')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (_, _) => const Scaffold(body: Text('PRIVACY')),
          ),
          GoRoute(
            path: '/terms-of-service',
            builder: (_, _) => const Scaffold(body: Text('TERMS')),
          ),
        ],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test Student');
      await tester.enterText(fields.at(1), 'new@test.com');
      await tester.enterText(fields.at(2), 'College1');
      await tester.enterText(fields.at(3), 'College1');
      await tester.ensureVisible(find.text('Create Account').last);
      await tester.tap(find.text('Create Account').last);
      await tester.pumpAndSettle();

      expect(auth.signUpEmailCalls, 0);
      expect(users.createCalls, 0);
    });

    testWidgets('creates account and routes to display-name setup',
        (tester) async {
      _setTallSurface(tester);
      final auth = FakeAuthService();
      final users = FakeUserRepository();
      await pumpRouterApp(
        tester,
        initialLocation: '/signup',
        overrides: testAuthOverrides(authService: auth, userRepository: users),
        routes: [
          GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('LOGIN')),
          ),
          GoRoute(
            path: '/profile/display-name-setup',
            builder: (_, _) => const Scaffold(body: Text('SETUP')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (_, _) => const Scaffold(body: Text('PRIVACY')),
          ),
          GoRoute(
            path: '/terms-of-service',
            builder: (_, _) => const Scaffold(body: Text('TERMS')),
          ),
        ],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test Student');
      await tester.enterText(fields.at(1), 'new@test.com');
      await tester.enterText(fields.at(2), 'College1');
      await tester.enterText(fields.at(3), 'College1');
      await tester.ensureVisible(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.ensureVisible(find.text('Create Account').last);
      await tester.tap(find.text('Create Account').last);
      await tester.pumpAndSettle();

      expect(auth.signUpEmailCalls, 1);
      expect(users.createCalls, 1);
      expect(find.text('SETUP'), findsOneWidget);
    });
  });

  group('Google Sign-in flow', () {
    testWidgets('cancellation stays on login', (tester) async {
      _setTallSurface(tester);
      final auth = FakeAuthService()..googleCancelled = true;
      await pumpRouterApp(
        tester,
        initialLocation: '/login',
        overrides: testAuthOverrides(authService: auth),
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/signup',
            builder: (_, _) => const Scaffold(body: Text('SIGNUP')),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const Scaffold(body: Text('FORGOT')),
          ),
        ],
      );

      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(auth.signInGoogleCalls, 1);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('success navigates home with fake user repo', (tester) async {
      _setTallSurface(tester);
      final auth = FakeAuthService();
      final users = FakeUserRepository();
      await pumpRouterApp(
        tester,
        initialLocation: '/login',
        overrides: testAuthOverrides(authService: auth, userRepository: users),
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/signup',
            builder: (_, _) => const Scaffold(body: Text('SIGNUP')),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const Scaffold(body: Text('FORGOT')),
          ),
          GoRoute(
            path: '/profile/display-name-setup',
            builder: (_, _) => const Scaffold(body: Text('SETUP')),
          ),
        ],
      );

      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(auth.signInGoogleCalls, 1);
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('Search Colleges flow', () {
    testWidgets('renders search UI and empty results state', (tester) async {
      _setTallSurface(tester);
      await pumpRouterApp(
        tester,
        initialLocation: '/college-search',
        overrides: [
          ...testAuthOverrides(),
          collegeDirectoryMetaProvider.overrideWith(
            (ref) async => const CollegeDirectoryMeta(totalColleges: 1),
          ),
          indianStatesProvider.overrideWith(
            (ref) async => <String>['Maharashtra'],
          ),
          indianCoursesProvider.overrideWith(
            (ref) async => <String>['B.Tech'],
          ),
          collegeSearchPageProvider.overrideWith(
            (ref, params) async => CollegeSearchPage(
              colleges: [_sampleCollege()],
            ),
          ),
        ],
        routes: [
          GoRoute(
            path: '/college-search',
            builder: (_, _) => const CollegeSearchScreen(),
          ),
        ],
      );

      expect(find.text('Search Colleges'), findsWidgets);
      expect(
        find.text('Search college, city, state, university...'),
        findsOneWidget,
      );
    });
  });

  group('Add My College flow', () {
    testWidgets('guest is prompted to sign in', (tester) async {
      await pumpScreen(
        tester,
        overrides: testAuthOverrides(),
        child: const RequestCollegeScreen(),
      );
      expect(find.text('Add My College'), findsOneWidget);
      expect(find.textContaining('Sign in to add your college'), findsOneWidget);
    });

    testWidgets('signed-in user sees request form', (tester) async {
      final mockUser = MockUser(
        uid: 'test-uid',
        email: 'student@example.com',
      );
      await pumpScreen(
        tester,
        overrides: testAuthOverrides(
          authService: FakeAuthService(initialUser: mockUser),
          userDetail: testUserModel(),
          firebaseUser: mockUser,
        ),
        child: const RequestCollegeScreen(),
      );
      expect(find.textContaining("Can't find your college"), findsOneWidget);
    });
  });

  group('Reviews flow', () {
    testWidgets('guest cannot write a review', (tester) async {
      await pumpScreen(
        tester,
        overrides: testAuthOverrides(),
        child: const WriteReviewScreen(
          collegeId: 'c1',
          collegeName: 'Test College',
        ),
      );
      expect(
        find.textContaining('Please log in to write a review'),
        findsOneWidget,
      );
    });
  });

  group('Community flow', () {
    testWidgets('hub shows community entry points', (tester) async {
      _setTallSurface(tester);
      await pumpScreen(
        tester,
        overrides: testAuthOverrides(),
        child: const CommunityHubScreen(),
      );
      expect(find.text('Student Community'), findsOneWidget);
      expect(find.text('Ask Seniors'), findsOneWidget);
    });
  });

  group('Profile flow', () {
    testWidgets('guest sees login prompt', (tester) async {
      await pumpScreen(
        tester,
        overrides: testAuthOverrides(),
        child: const ProfileScreen(),
      );
      expect(
        find.text('Please log in to view your profile'),
        findsOneWidget,
      );
    });

    testWidgets('signed-in user sees profile chrome', (tester) async {
      _setTallSurface(tester);
      final mockUser = MockUser(
        uid: 'test-uid',
        email: 'student@example.com',
        displayName: 'Test Student',
      );
      await pumpScreen(
        tester,
        overrides: [
          ...testAuthOverrides(
            authService: FakeAuthService(initialUser: mockUser),
            userDetail: testUserModel(),
            firebaseUser: mockUser,
          ),
          isAdminProvider.overrideWith((ref) async => false),
        ],
        child: const ProfileScreen(),
      );
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Test Student'), findsWidgets);
    });
  });
}