import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/admin/providers/admin_provider.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/home/widgets/home_header_widget.dart';
import 'package:college_reality_india/features/home/widgets/home_navigation_drawer.dart';
import 'package:college_reality_india/features/home/widgets/user_quick_profile_sheet.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

final _signedIn = MockUser(
  uid: 'u1',
  email: 'student@example.com',
  displayName: 'Test Student',
);

UserModel _detail({
  String? phone,
  String badge = VerificationConstants.badgeNone,
  String status = VerificationConstants.statusIncomplete,
}) =>
    testUserModel(uid: 'u1', email: 'student@example.com').copyWith(
      phone: phone,
      verificationBadge: badge,
      verificationStatus: status,
    );

List<GoRoute> _drawerHostRoutes() => [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          appBar: AppBar(),
          drawer: const HomeNavigationDrawer(),
          body: const SizedBox.expand(),
        ),
      ),
      for (final path in [
        RouteNames.collegeSearch,
        RouteNames.myReviews,
        RouteNames.favorites,
        RouteNames.notifications,
        RouteNames.admin,
        RouteNames.login,
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('at $path')),
        ),
    ];

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeNavigationDrawer', () {
    testWidgets('signed-in user sees the five destinations and no admin item',
        (tester) async {
      await pumpRouterApp(
        tester,
        initialLocation: '/',
        routes: _drawerHostRoutes(),
        overrides: [
          ...testAuthOverrides(
            firebaseUser: _signedIn,
            userDetail: _detail(),
          ),
          isAdminProvider.overrideWith((ref) async => false),
        ],
      );
      await _openDrawer(tester);

      for (final label in [
        'Search Colleges',
        'My Reviews',
        'Bookmarks',
        'Notifications',
        'Sign Out',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Admin Panel'), findsNothing);
      // Nothing left over from the old profile menu.
      expect(find.text('My Profile'), findsNothing);
    });

    testWidgets('admin also sees Admin Panel', (tester) async {
      await pumpRouterApp(
        tester,
        initialLocation: '/',
        routes: _drawerHostRoutes(),
        overrides: [
          ...testAuthOverrides(
            firebaseUser: _signedIn,
            userDetail: _detail(),
          ),
          isAdminProvider.overrideWith((ref) async => true),
        ],
      );
      await _openDrawer(tester);

      expect(find.text('Admin Panel'), findsOneWidget);
    });

    testWidgets('signed-out visitor only gets Search and Sign in',
        (tester) async {
      await pumpRouterApp(
        tester,
        initialLocation: '/',
        routes: _drawerHostRoutes(),
        overrides: testAuthOverrides(),
      );
      await _openDrawer(tester);

      expect(find.text('Search Colleges'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('My Reviews'), findsNothing);
      expect(find.text('Bookmarks'), findsNothing);
      expect(find.text('Sign Out'), findsNothing);
    });

    testWidgets('tapping an item closes the drawer and navigates',
        (tester) async {
      await pumpRouterApp(
        tester,
        initialLocation: '/',
        routes: _drawerHostRoutes(),
        overrides: [
          ...testAuthOverrides(
            firebaseUser: _signedIn,
            userDetail: _detail(),
          ),
          isAdminProvider.overrideWith((ref) async => false),
        ],
      );
      await _openDrawer(tester);

      await tester.tap(find.text('My Reviews'));
      await tester.pumpAndSettle();

      expect(find.text('at ${RouteNames.myReviews}'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('Sign Out asks for confirmation and Cancel keeps the session',
        (tester) async {
      await pumpRouterApp(
        tester,
        initialLocation: '/',
        routes: _drawerHostRoutes(),
        overrides: [
          ...testAuthOverrides(
            firebaseUser: _signedIn,
            userDetail: _detail(),
          ),
          isAdminProvider.overrideWith((ref) async => false),
        ],
      );
      await _openDrawer(tester);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out?'), findsNothing);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('at ${RouteNames.login}'), findsNothing);
    });
  });

  group('UserQuickProfileSheet', () {
    Future<List<String>> pumpSheet(
      WidgetTester tester,
      UserModel detail,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final navigated = <String>[];
      await pumpScreen(
        tester,
        overrides: testAuthOverrides(
          firebaseUser: _signedIn,
          userDetail: detail,
        ),
        child: Scaffold(
          body: UserQuickProfileSheet(onNavigate: navigated.add),
        ),
      );
      return navigated;
    }

    testWidgets('shows only identity, contact, verify and edit', (tester) async {
      await pumpSheet(tester, _detail(phone: '+919876543210'));

      expect(find.text('Test Student'), findsOneWidget);
      expect(find.text('student@example.com'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('Verify Student Badge'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      // The navigation menu moved to the drawer.
      for (final gone in [
        'My Reviews',
        'Bookmarks',
        'Notifications',
        'Search Colleges',
        'Admin Panel',
        'Sign Out',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('missing mobile number reads Not added', (tester) async {
      await pumpSheet(tester, _detail());

      expect(find.text('Not added'), findsOneWidget);
    });

    testWidgets('Verify and Edit route to their screens', (tester) async {
      final navigated = await pumpSheet(tester, _detail());

      await tester.tap(find.text('Verify Student Badge'));
      await tester.tap(find.text('Edit Profile'));

      expect(navigated, [RouteNames.verification, RouteNames.editProfile]);
    });

    testWidgets('approved badge shows status instead of a verify button',
        (tester) async {
      await pumpSheet(
        tester,
        _detail(
          badge: VerificationConstants.badgeVerifiedStudent,
          status: VerificationConstants.statusApproved,
        ),
      );

      expect(find.text('Verified Student'), findsOneWidget);
      expect(find.text('Verify Student Badge'), findsNothing);
    });

    testWidgets('pending review shows in-review status', (tester) async {
      await pumpSheet(
        tester,
        _detail(status: VerificationConstants.statusPendingReview),
      );

      expect(find.text('Verification in review'), findsOneWidget);
      expect(find.text('Verify Student Badge'), findsNothing);
    });

    testWidgets('rejected verification offers resubmission', (tester) async {
      await pumpSheet(
        tester,
        _detail(status: VerificationConstants.statusRejected),
      );

      expect(find.text('Resubmit Verification Documents'), findsOneWidget);
    });
  });

  testWidgets('tapping the avatar opens the quick profile sheet',
      (tester) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Center(child: HomeHeaderActions(user: _signedIn, onDark: false)),
          ),
        ),
      ],
      overrides: testAuthOverrides(
        firebaseUser: _signedIn,
        userDetail: _detail(),
      ),
    );

    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Sign Out'), findsNothing);
  });
}
