import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../bootstrap/app_error_handler.dart';

void _log(String message) => debugPrint('[AuthService] $message');

/// Actionable next step for the FirebaseAuthException codes that mean an
/// email-auth **project misconfiguration** rather than user error — so a
/// "verification email never arrives" is self-diagnosing in local dev.
String? _emailDiagnosticHint(String code) {
  switch (code) {
    case 'operation-not-allowed':
      return 'Email/Password sign-in is DISABLED. Enable it: Firebase '
          'Console -> Authentication -> Sign-in method -> Email/Password.';
    case 'unauthorized-continue-uri':
    case 'invalid-continue-uri':
    case 'missing-continue-uri':
      return 'ActionCodeSettings.url host is not in Authentication -> '
          'Settings -> Authorized domains. Remove the ActionCodeSettings or '
          'add the domain.';
    case 'invalid-dynamic-link-domain':
      return 'ActionCodeSettings references a Firebase Dynamic Links domain '
          '(deprecated / shut down). Drop the `dynamicLinkDomain` and the '
          'Android/iOS blocks and use the plain default handler.';
    case 'too-many-requests':
      return 'Firebase throttled this sender/device. Wait, or test from a '
          'different network/account.';
    case 'network-request-failed':
      return 'Device could not reach Firebase. Check connectivity / proxy / '
          'emulator DNS.';
    default:
      return null;
  }
}

void _logAuthException(String op, Object e, [StackTrace? st]) {
  if (e is FirebaseAuthException) {
    final hint = _emailDiagnosticHint(e.code);
    _log(
      '$op FAILED code=${e.code} message=${e.message}'
      '${hint == null ? '' : '\n  ↳ FIX: $hint'}',
    );
  } else {
    _log('$op FAILED (${e.runtimeType}): $e');
  }
  // No-op in debug; non-fatal Crashlytics record in release so silent
  // email-dispatch failures are visible in production too.
  AppErrorHandler.recordNonFatal(e, st, reason: 'AuthService.$op');
}

/// Auth operations used by [AuthNotifier] and screens.
abstract class AuthServiceApi {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential?> signInWithGoogle();
  Future<void> signOut();
  Future<void> updateUserProfile({String? displayName, String? photoURL});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<bool> reloadUser();
}

class AuthService implements AuthServiceApi {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              clientId: kIsWeb ? _webClientId : null,
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static const String _webClientId =
      '244446156099-bb6c7e0dabe7a5efbf0bf6.apps.googleusercontent.com';

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, st) {
      // Surfaces `operation-not-allowed` (Email/Password provider disabled)
      // and `network-request-failed` — the two silent causes of "email
      // auth doesn't work" — with the real code, before AuthNotifier maps
      // it to a generic user string.
      _logAuthException('signUpWithEmail', e, st);
      rethrow;
    }
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, st) {
      _logAuthException('signInWithEmail', e, st);
      rethrow;
    }
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _firebaseAuth.signInWithPopup(provider);
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      if (!kIsWeb) _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    await currentUser?.updateDisplayName(displayName);
    await currentUser?.updatePhotoURL(photoURL);
    await currentUser?.reload();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // No ActionCodeSettings — see sendEmailVerification for why.
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _log('sendPasswordResetEmail dispatched to $email');
    } catch (e, st) {
      _logAuthException('sendPasswordResetEmail', e, st);
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'You must be logged in to verify your email.',
      );
    }
    if (user.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-already-verified',
        message: 'Your email is already verified.',
      );
    }
    try {
      // Deliberately NO ActionCodeSettings: the default Firebase-hosted
      // action handler needs zero extra setup. Passing an
      // ActionCodeSettings whose `url` host isn't in Authentication ->
      // Settings -> Authorized domains, or a `dynamicLinkDomain` (Dynamic
      // Links is shut down), makes this call throw
      // `unauthorized-continue-uri` / `invalid-dynamic-link-domain` — the
      // classic "verification email silently never arrives". Add one here
      // only after a custom domain is verified in the console.
      await user.sendEmailVerification();
      _log('sendEmailVerification dispatched to ${user.email}');
    } on FirebaseAuthException catch (e, st) {
      _logAuthException('sendEmailVerification', e, st);
      rethrow;
    } catch (e, st) {
      _logAuthException('sendEmailVerification', e, st);
      // Keep the real detail instead of masking every failure as a
      // network error.
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Could not send verification email: $e',
      );
    }
  }

  @override
  Future<bool> reloadUser() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }
}
