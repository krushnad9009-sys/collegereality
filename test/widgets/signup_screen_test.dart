import 'package:college_reality_india/features/auth/screens/signup_screen.dart';
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

  List<GoRoute> routes() => [
        GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
        GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('LOGIN'))),
        GoRoute(
          path: '/profile/display-name-setup',
          builder: (_, _) => const Scaffold(body: Text('SETUP')),
        ),
        GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('HOME'))),
        GoRoute(
          path: '/privacy-policy',
          builder: (_, _) => const Scaffold(body: Text('PRIVACY')),
        ),
        GoRoute(
          path: '/terms-of-service',
          builder: (_, _) => const Scaffold(body: Text('TERMS')),
        ),
      ];

  testWidgets('SignupScreen renders required fields', (tester) async {
    setTallSurface(tester);
    await pumpRouterApp(
      tester,
      initialLocation: '/signup',
      overrides: testAuthOverrides(),
      routes: routes(),
    );

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('SignupScreen blocks submit when form invalid', (tester) async {
    setTallSurface(tester);
    final auth = FakeAuthService();
    await pumpRouterApp(
      tester,
      initialLocation: '/signup',
      overrides: testAuthOverrides(authService: auth),
      routes: routes(),
    );

    await tester.ensureVisible(find.text('Create Account').last);
    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();

    expect(auth.signUpEmailCalls, 0);
  });
}