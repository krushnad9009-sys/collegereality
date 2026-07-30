import 'package:college_reality_india/features/auth/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('HOME'))),
        GoRoute(path: '/signup', builder: (_, _) => const Scaffold(body: Text('SIGNUP'))),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const Scaffold(body: Text('FORGOT')),
        ),
      ];

  testWidgets('LoginScreen shows email/password and Google controls',
      (tester) async {
    setTallSurface(tester);
    final auth = FakeAuthService();
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      overrides: testAuthOverrides(authService: auth),
      routes: routes(),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('LoginScreen validates empty form before auth call', (tester) async {
    setTallSurface(tester);
    final auth = FakeAuthService();
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      overrides: testAuthOverrides(authService: auth),
      routes: routes(),
    );

    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(auth.signInEmailCalls, 0);
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('LoginScreen signs in with email via FakeAuthService', (tester) async {
    setTallSurface(tester);
    final auth = FakeAuthService();
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      overrides: testAuthOverrides(authService: auth),
      routes: routes(),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'student@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'College1');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(auth.signInEmailCalls, 1);
    expect(auth.lastEmail, 'student@test.com');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('LoginScreen surfaces Firebase auth errors', (tester) async {
    setTallSurface(tester);
    final auth = FakeAuthService()
      ..emailSignInError = FirebaseAuthException(code: 'wrong-password');
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      overrides: testAuthOverrides(authService: auth),
      routes: routes(),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'student@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'College1');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Incorrect password'), findsWidgets);
  });

  testWidgets('Google sign-in cancellation stays on login', (tester) async {
    setTallSurface(tester);
    final auth = FakeAuthService()..googleCancelled = true;
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      overrides: testAuthOverrides(authService: auth),
      routes: routes(),
    );

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.signInGoogleCalls, 1);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}