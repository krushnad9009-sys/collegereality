import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:college_reality_india/features/auth/providers/user_provider.dart';
import 'package:college_reality_india/features/legal/screens/legal_screens.dart';
import 'package:college_reality_india/features/onboarding/screens/permissions_terms_screen.dart';
import 'package:college_reality_india/features/onboarding/services/onboarding_location_resolver.dart';
import 'package:college_reality_india/features/onboarding/services/onboarding_permission_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_harness.dart';

/// Records which OS permissions were requested, in order, with canned answers.
class _FakePermissions extends OnboardingPermissionService {
  final calls = <String>[];
  final bool photos;
  final bool notifications;
  final OnboardingLocationResult location;

  _FakePermissions({
    this.photos = true,
    this.notifications = true,
    this.location = const OnboardingLocationResult(
      granted: true,
      state: 'Maharashtra',
      city: 'Pune',
    ),
  });

  @override
  Future<bool> requestPhotos() async {
    calls.add('photos');
    return photos;
  }

  @override
  Future<bool> requestNotifications() async {
    calls.add('notifications');
    return notifications;
  }

  @override
  Future<OnboardingLocationResult> requestLocation() async {
    calls.add('location');
    return location;
  }
}

const _acceptLabel = 'I Accept Terms & Grant Permissions';

void main() {
  final now = DateTime(2026, 1, 1);

  UserModel newUser({bool terms = false, bool permissions = false}) =>
      UserModel(
        uid: 'u1',
        email: 'a@b.com',
        hasAcceptedTerms: terms,
        termsAcceptedAt: terms ? DateTime(2026, 3, 3) : null,
        hasCompletedPermissionsOnboarding: permissions,
        createdAt: now,
        updatedAt: now,
      );

  late FakeUserRepository repo;
  late _FakePermissions permissions;

  Future<void> pumpGate(
    WidgetTester tester, {
    required UserModel user,
    Size size = const Size(800, 1300),
  }) async {
    AppFonts.useSystemFallback = true;
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    repo = FakeUserRepository()..users[user.uid] = user;
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(repo),
        onboardingPermissionServiceProvider.overrideWithValue(permissions),
        currentUserProvider.overrideWith(
          (ref) => MockUser(uid: 'u1', email: 'a@b.com'),
        ),
        currentUserDetailProvider.overrideWith((ref) async => repo.users['u1']),
      ],
    );
    addTearDown(container.dispose);
    // The router awaits the user doc before showing the gate; do the same.
    await container.read(currentUserDetailProvider.future);

    final router = GoRouter(
      initialLocation: RouteNames.permissionsAndTerms,
      routes: [
        GoRoute(
          path: RouteNames.permissionsAndTerms,
          builder: (_, _) => const PermissionsTermsScreen(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (_, _) => const Scaffold(body: Text('HOME SCREEN')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => permissions = _FakePermissions());

  testWidgets('shows the complete Terms inline, scrollable to the last clause', (
    tester,
  ) async {
    await pumpGate(tester, user: newUser());

    expect(find.text(termsAndConditionsIntro), findsOneWidget);
    expect(find.text(termsOfServiceSections.first.heading), findsOneWidget);

    final termsScrollable = find.descendant(
      of: find.byKey(const ValueKey('terms-card')),
      matching: find.byType(Scrollable),
    );
    // The final clause is reachable by scrolling the card, not hidden behind
    // a link.
    await tester.scrollUntilVisible(
      find.text(termsOfServiceSections.last.heading),
      300,
      scrollable: termsScrollable,
    );
    expect(find.text(termsOfServiceSections.last.heading), findsOneWidget);
    expect(termsOfServiceSections, hasLength(9));
  });

  testWidgets('offers all three permissions and one accept action', (
    tester,
  ) async {
    await pumpGate(tester, user: newUser());

    expect(find.text('Gallery / Photos'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text(_acceptLabel), findsOneWidget);
  });

  testWidgets('one tap requests every permission in order, records both '
      'halves and goes straight to Home', (tester) async {
    await pumpGate(tester, user: newUser());

    await tester.tap(find.text(_acceptLabel));
    await tester.pumpAndSettle();

    expect(permissions.calls, ['photos', 'location', 'notifications']);
    expect(repo.completeOnboardingCalls, hasLength(1));
    final call = repo.completeOnboardingCalls.single;
    expect(call.recordTerms, isTrue);
    expect(call.recordPermissions, isTrue);
    expect(call.state, 'Maharashtra');
    expect(repo.users['u1']!.hasCompletedOnboarding, isTrue);
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('a permission switched off is not requested', (tester) async {
    await pumpGate(tester, user: newUser());

    await tester.tap(
      find.byKey(const ValueKey('permission-switch-Notifications')),
    );
    await tester.pump();
    await tester.tap(find.text(_acceptLabel));
    await tester.pumpAndSettle();

    expect(permissions.calls, ['photos', 'location']);
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('with every permission off the button honestly says accept-only', (
    tester,
  ) async {
    await pumpGate(tester, user: newUser());

    for (final name in ['Gallery / Photos', 'Location', 'Notifications']) {
      await tester.tap(find.byKey(ValueKey('permission-switch-$name')));
    }
    await tester.pump();
    expect(find.text(_acceptLabel), findsNothing);

    await tester.tap(find.text('I Accept Terms'));
    await tester.pumpAndSettle();

    expect(permissions.calls, isEmpty);
    // Terms recorded, Home reached, permissions answered as "not provided".
    expect(repo.completeOnboardingCalls.single.state, 'Not Provided');
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('denied permissions never block reaching Home', (tester) async {
    permissions = _FakePermissions(
      photos: false,
      notifications: false,
      location: OnboardingLocationResult.notProvided,
    );
    await pumpGate(tester, user: newUser());

    await tester.tap(find.text(_acceptLabel));
    await tester.pumpAndSettle();

    expect(find.text('HOME SCREEN'), findsOneWidget);
    expect(repo.users['u1']!.hasCompletedOnboarding, isTrue);
  });

  testWidgets('a failed save keeps the user here, and a retry does not '
      're-ask permissions', (tester) async {
    await pumpGate(tester, user: newUser());
    repo.completeOnboardingError = StateError('offline');

    await tester.tap(find.text(_acceptLabel));
    await tester.pumpAndSettle();

    expect(find.text('HOME SCREEN'), findsNothing);
    expect(find.text('Welcome to College Reality'), findsOneWidget);
    expect(repo.users['u1']!.hasAcceptedTerms, isFalse);
    expect(permissions.calls, ['photos', 'location', 'notifications']);

    // Every permission has been answered, so the retry button no longer
    // claims to grant anything.
    expect(find.text(_acceptLabel), findsNothing);
    repo.completeOnboardingError = null;
    await tester.tap(find.text('I Accept Terms'));
    await tester.pumpAndSettle();

    expect(find.text('HOME SCREEN'), findsOneWidget);
    // Not asked a second time.
    expect(permissions.calls, ['photos', 'location', 'notifications']);
    expect(repo.users['u1']!.hasAcceptedTerms, isTrue);
  });

  testWidgets('an account that already accepted Terms only sees permissions '
      'and its original acceptance date is preserved', (tester) async {
    await pumpGate(tester, user: newUser(terms: true));

    expect(find.byKey(const ValueKey('terms-card')), findsNothing);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final call = repo.completeOnboardingCalls.single;
    expect(call.recordTerms, isFalse);
    expect(call.recordPermissions, isTrue);
    expect(repo.users['u1']!.termsAcceptedAt, DateTime(2026, 3, 3));
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('does not overflow on a short phone and keeps the button '
      'reachable', (tester) async {
    await pumpGate(tester, user: newUser(), size: const Size(360, 520));

    expect(tester.takeException(), isNull);
    expect(find.text(_acceptLabel), findsOneWidget);
    final button = tester.getRect(find.text(_acceptLabel));
    expect(button.bottom, lessThanOrEqualTo(520));
  });
}
