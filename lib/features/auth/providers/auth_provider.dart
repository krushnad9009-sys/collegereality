import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';

final authServiceProvider = Provider<AuthServiceApi>((ref) {
  return AuthService();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  // Prefer auth notifier user so reload() after email verification triggers UI updates.
  final notifierUser = ref.watch(authProvider.select((state) => state.user));
  if (notifierUser != null) return notifierUser;

  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  factory AuthException.fromFirebaseException(FirebaseAuthException e) {
    return AuthException(
      message: _getErrorMessage(e.code),
      code: e.code,
    );
  }

  static String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'email-already-verified':
        return 'Your email is already verified.';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password';
      case 'requires-recent-login':
        return 'Please sign in again to continue this action';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      default:
        return 'An error occurred. Please try again';
    }
  }

  @override
  String toString() => message;
}

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthServiceApi _authService;
  final Ref ref;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authService, this.ref) : super(AuthState()) {
    _initAuthState();
  }

  void _initAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
      );
    }
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user == null) {
        state = AuthState();
      } else {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signUpWithEmail(email, password);
      await _authService.sendEmailVerification();
      state = state.copyWith(
        user: credential.user,
        isAuthenticated: true,
        isLoading: false,
      );
    } on FirebaseAuthException catch (e) {
      final exception = AuthException.fromFirebaseException(e);
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithEmail(email, password);
      await _authService.reloadUser();
      state = state.copyWith(
        user: _authService.currentUser ?? credential.user,
        isAuthenticated: true,
        isLoading: false,
      );
    } on FirebaseAuthException catch (e) {
      final exception = AuthException.fromFirebaseException(e);
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        state = state.copyWith(
          user: credential.user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Google sign-in was cancelled',
          isLoading: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      final exception = AuthException.fromFirebaseException(e);
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to sign out',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      final exception = AuthException.fromFirebaseException(e);
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendEmailVerification();
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      final exception = AuthException.fromFirebaseException(e);
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send verification email',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<bool> refreshEmailVerificationStatus() async {
    final verified = await _authService.reloadUser();
    state = state.copyWith(user: _authService.currentUser);
    return verified;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
