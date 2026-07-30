import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthException.fromFirebaseException', () {
    test('maps common auth codes to clear messages', () {
      expect(
        AuthException.fromFirebaseException(
          FirebaseAuthException(code: 'user-not-found'),
        ).message,
        'No account found with this email address',
      );
      expect(
        AuthException.fromFirebaseException(
          FirebaseAuthException(code: 'wrong-password'),
        ).message,
        'Incorrect password',
      );
      expect(
        AuthException.fromFirebaseException(
          FirebaseAuthException(code: 'invalid-credential'),
        ).message,
        'Invalid email or password',
      );
      expect(
        AuthException.fromFirebaseException(
          FirebaseAuthException(code: 'requires-recent-login'),
        ).message,
        'Please sign in again to continue this action',
      );
      expect(
        AuthException.fromFirebaseException(
          FirebaseAuthException(code: 'some-unknown'),
        ).message,
        'An error occurred. Please try again',
      );
    });
  });

  group('AuthState.copyWith', () {
    test('preserves and overrides fields', () {
      final state = AuthState(isLoading: true, isAuthenticated: false);
      final next = state.copyWith(isAuthenticated: true, error: 'x');
      expect(next.isLoading, isTrue);
      expect(next.isAuthenticated, isTrue);
      expect(next.error, 'x');
    });
  });
}
