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
    case 'internal-error':
      return 'Transient Firebase Auth error (token-refresh race, or a '
          'reload right after a server-side user change). Safe to retry — '
          'reloadUser() already retries once and then falls back to the '
          'cached emailVerified flag.';
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

  /// Reloads the Firebase user and returns `emailVerified`. Email
  /// verification itself is now a custom OTP flow (`EmailOtpService` /
  /// `functions/src/emailOtp.js`); this just observes the flag the
  /// `verifyEmailOtp` function sets server-side.
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
    // Google sign-out is best-effort: it throws if the user never signed
    // in with Google, or if the plugin isn't initialised, and that must
    // NOT abort (or, via Future.wait, block) the Firebase sign-out that
    // actually ends the session.
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        _log('Google signOut failed (ignored): $e');
      }
    }
    await _firebaseAuth.signOut();
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
      // No ActionCodeSettings: the default Firebase-hosted reset handler
      // needs zero setup; a bad `url`/`dynamicLinkDomain` is the classic
      // cause of a reset email that silently never arrives.
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _log('sendPasswordResetEmail dispatched to $email');
    } catch (e, st) {
      _logAuthException('sendPasswordResetEmail', e, st);
      rethrow;
    }
  }

  // Email verification is no longer a Firebase email *link*
  // (`user.sendEmailVerification()`). It's a custom 6-digit OTP: the
  // `requestEmailOtp` / `verifyEmailOtp` Cloud Functions email a code and,
  // on success, set `emailVerified` server-side. The client sends/verifies
  // codes through `EmailOtpService`; [reloadUser] below is how it then
  // observes the flag.

  @override
  Future<bool> reloadUser() async {
    final user = currentUser;
    if (user == null) return false;

    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await user.reload();
        return currentUser?.emailVerified ?? false;
      } on FirebaseAuthException catch (e, st) {
        // `[firebase_auth/internal-error]` from reload() is a known
        // transient Firebase Auth state — it commonly fires the first
        // time the client reloads right after the server changed the user
        // record out-of-band (the verifyEmailOtp Cloud Function's
        // `admin.auth().updateUser(uid, {emailVerified: true})`), or
        // during an ID-token refresh race. Log the FULL stack trace,
        // retry once after a short delay, then fall back to the cached
        // flag rather than surfacing a hard failure for something the
        // server has already done.
        _log(
          'reloadUser attempt $attempt FAILED code=${e.code} '
          'message=${e.message} plugin=${e.plugin}',
        );
        debugPrintStack(
          stackTrace: st,
          label: '[AuthService] reloadUser FirebaseAuthException',
        );
        _logAuthException('reloadUser', e, st);
        if (attempt == 1 && e.code == 'internal-error') {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue;
        }
        return currentUser?.emailVerified ?? false;
      } catch (e, st) {
        _logAuthException('reloadUser', e, st);
        return currentUser?.emailVerified ?? false;
      }
    }
    return currentUser?.emailVerified ?? false;
  }
}
