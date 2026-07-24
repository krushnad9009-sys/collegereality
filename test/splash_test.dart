import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/features/auth/screens/splash_screen.dart';

void main() {
  group('resolveSplashRoute', () {
    test('logged in user goes to home', () {
      expect(
        resolveSplashRoute(isLoggedIn: true, hasSeenOnboarding: false),
        RouteNames.home,
      );
    });

    test('returning guest goes to login', () {
      expect(
        resolveSplashRoute(isLoggedIn: false, hasSeenOnboarding: true),
        RouteNames.login,
      );
    });

    test('first-time user goes to onboarding', () {
      expect(
        resolveSplashRoute(isLoggedIn: false, hasSeenOnboarding: false),
        RouteNames.onboarding,
      );
    });
  });
}
