import 'package:college_reality_india/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ForgotPasswordScreen renders email field', (tester) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/forgot-password',
      overrides: testAuthOverrides(),
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });
}