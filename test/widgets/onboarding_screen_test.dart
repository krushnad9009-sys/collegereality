import 'package:college_reality_india/features/auth/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpOnboardingStep(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  List<GoRoute> routes() => [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN')),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, _) => const Scaffold(body: Text('SIGNUP')),
        ),
      ];

  testWidgets('OnboardingScreen shows first page content', (tester) async {
    setTallSurface(tester);
    await pumpRouterApp(
      tester,
      initialLocation: '/onboarding',
      overrides: testAuthOverrides(),
      routes: routes(),
    );

    expect(find.textContaining('Real reviews'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('TRUST BEFORE YOU CHOOSE'), findsOneWidget);
  });

  testWidgets('OnboardingScreen advances through pages', (tester) async {
    setTallSurface(tester);
    await pumpRouterApp(
      tester,
      initialLocation: '/onboarding',
      overrides: testAuthOverrides(),
      routes: routes(),
    );

    expect(find.textContaining('Real reviews'), findsOneWidget);

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await pumpOnboardingStep(tester);

    expect(find.textContaining('Compare colleges'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('OnboardingScreen Get Started navigates to login', (tester) async {
    setTallSurface(tester);
    await pumpRouterApp(
      tester,
      initialLocation: '/onboarding',
      overrides: testAuthOverrides(),
      routes: routes(),
    );

    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await pumpOnboardingStep(tester);
    }

    expect(find.text('Get Started'), findsOneWidget);
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await pumpOnboardingStep(tester);

    expect(find.text('LOGIN'), findsOneWidget);
  });
}