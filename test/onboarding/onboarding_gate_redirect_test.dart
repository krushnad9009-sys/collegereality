import 'package:college_reality_india/config/router/app_router.dart';
import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  UserModel user({bool terms = false, bool permissions = false}) => UserModel(
    uid: 'u1',
    email: 'a@b.com',
    hasAcceptedTerms: terms,
    hasCompletedPermissionsOnboarding: permissions,
    createdAt: now,
    updatedAt: now,
  );

  group('UserModel.hasCompletedOnboarding', () {
    test('needs BOTH terms and the permissions step', () {
      expect(user().hasCompletedOnboarding, isFalse);
      expect(user(terms: true).hasCompletedOnboarding, isFalse);
      expect(user(permissions: true).hasCompletedOnboarding, isFalse);
      expect(
        user(terms: true, permissions: true).hasCompletedOnboarding,
        isTrue,
      );
    });
  });

  group('onboardingGateRedirect', () {
    const gate = RouteNames.permissionsAndTerms;

    test('a new account is sent to the gate from Home and any other route', () {
      for (final path in [
        RouteNames.home,
        RouteNames.profile,
        RouteNames.collegeSearch,
        RouteNames.privacyPolicy,
        '/college-details/abc',
      ]) {
        expect(
          onboardingGateRedirect(path: path, user: user()),
          gate,
          reason: path,
        );
      }
    });

    test(
      'an account with only terms accepted still owes the permissions half',
      () {
        expect(
          onboardingGateRedirect(path: RouteNames.home, user: user(terms: true)),
          gate,
        );
      },
    );

    test('the gate itself is left alone while onboarding is unfinished', () {
      expect(onboardingGateRedirect(path: gate, user: user()), isNull);
    });

    test('a finished account goes straight to Home and is never re-gated', () {
      final done = user(terms: true, permissions: true);
      expect(onboardingGateRedirect(path: RouteNames.home, user: done), isNull);
      expect(
        onboardingGateRedirect(path: RouteNames.profile, user: done),
        isNull,
      );
      // Stale bookmark / back button onto the gate.
      expect(onboardingGateRedirect(path: gate, user: done), RouteNames.home);
    });

    test('an unknown user doc never traps anyone at the gate', () {
      expect(onboardingGateRedirect(path: RouteNames.home, user: null), isNull);
      expect(onboardingGateRedirect(path: gate, user: null), RouteNames.home);
    });
  });
}
