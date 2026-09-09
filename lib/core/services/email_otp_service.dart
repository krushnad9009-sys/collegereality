import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../bootstrap/app_error_handler.dart';

void _log(String message) => debugPrint('[EmailOtpService] $message');

/// Result of a successful [EmailOtpService.requestOtp] call.
class EmailOtpRequestResult {
  /// Seconds the caller should disable the "resend" action for.
  final int retryAfterSeconds;

  /// Seconds until the emailed code stops being accepted.
  final int expiresInSeconds;

  const EmailOtpRequestResult({
    required this.retryAfterSeconds,
    required this.expiresInSeconds,
  });
}

/// Typed failure from either email-OTP callable. [code] is the
/// `FirebaseFunctionsException.code` (e.g. `resource-exhausted`,
/// `invalid-argument`, `deadline-exceeded`, `unavailable`).
class EmailOtpException implements Exception {
  final String message;
  final String? code;

  /// Present on `resource-exhausted` (cooldown / hourly cap) — seconds to
  /// wait before retrying.
  final int? retryAfterSeconds;

  /// Present on a wrong-code `invalid-argument` — verification attempts
  /// left before the code is invalidated.
  final int? attemptsLeft;

  EmailOtpException(
    this.message, {
    this.code,
    this.retryAfterSeconds,
    this.attemptsLeft,
  });

  @override
  String toString() => message;
}

/// Client for the custom email-OTP verification flow. Firebase Auth has no
/// email-OTP primitive; this calls the `requestEmailOtp` / `verifyEmailOtp`
/// Cloud Functions (see `functions/src/emailOtp.js`), which own code
/// generation, storage, rate limiting, delivery (Resend), and finally
/// setting the Firebase Auth user's `emailVerified` flag.
class EmailOtpService {
  EmailOtpService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Requests a fresh code. This is also the **Resend** path: the
  /// `requestEmailOtp` function fully overwrites `email_otps/{uid}` — new
  /// salt, new hash, `attempts` reset to 0, new 10-minute expiry — so the
  /// previously issued code is invalidated server-side by this call alone.
  /// The caller still needs to clear its own local input state (see
  /// `EmailVerificationSection`).
  Future<EmailOtpRequestResult> requestOtp() async {
    try {
      _log('requestEmailOtp: calling (prior code, if any, is invalidated)');
      final res = await _functions
          .httpsCallable('requestEmailOtp')
          .call<Map<dynamic, dynamic>>();
      final data = Map<String, dynamic>.from(res.data);
      _log('requestEmailOtp: ok');
      return EmailOtpRequestResult(
        retryAfterSeconds: (data['retryAfterSeconds'] as num?)?.toInt() ?? 60,
        expiresInSeconds: (data['expiresInSeconds'] as num?)?.toInt() ?? 600,
      );
    } on FirebaseFunctionsException catch (e, st) {
      throw _mapFunctions('requestEmailOtp', e, st);
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuth('requestEmailOtp', e, st);
    } catch (e, st) {
      throw _mapUnknown('requestEmailOtp', e, st);
    }
  }

  /// Verifies [code]. Returns normally only when the server has confirmed
  /// the code — at which point the Firebase Auth user is `emailVerified`
  /// server-side and the caller should `reloadUser()` to observe it (a
  /// failure of that reload is NOT a verification failure).
  Future<void> verifyOtp(String code) async {
    // Never hand Firebase / the callable an empty or malformed value.
    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      throw EmailOtpException('Enter the 6-digit code.', code: 'invalid-argument');
    }
    try {
      _log('verifyEmailOtp: calling');
      await _functions
          .httpsCallable('verifyEmailOtp')
          .call<Map<dynamic, dynamic>>({'code': trimmed});
      _log('verifyEmailOtp: ok');
    } on FirebaseFunctionsException catch (e, st) {
      throw _mapFunctions('verifyEmailOtp', e, st);
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuth('verifyEmailOtp', e, st);
    } catch (e, st) {
      throw _mapUnknown('verifyEmailOtp', e, st);
    }
  }

  EmailOtpException _mapFunctions(
    String op,
    FirebaseFunctionsException e,
    StackTrace st,
  ) {
    final details = e.details is Map
        ? Map<String, dynamic>.from(e.details as Map)
        : const <String, dynamic>{};
    final retryAfterSeconds = (details['retryAfterSeconds'] as num?)?.toInt();
    final attemptsLeft = (details['attemptsLeft'] as num?)?.toInt();

    // Log the EXACT wire code + message BEFORE it is replaced with a
    // user-facing string — this line is what actually explains a report of
    // "Something went wrong" on screen. The code is echoed into the
    // Crashlytics `reason` too so it is filterable in release.
    _log('$op FAILED FirebaseFunctionsException '
        'code=${e.code} message=${e.message} details=$details\n$st');
    AppErrorHandler.recordNonFatal(
      e,
      st,
      reason: 'EmailOtpService.$op [functions/${e.code}]',
    );

    return EmailOtpException(
      _friendlyFunctionsMessage(op, e, retryAfterSeconds),
      code: e.code,
      retryAfterSeconds: retryAfterSeconds,
      attemptsLeft: attemptsLeft,
    );
  }

  /// Turns a `FirebaseFunctionsException.code` into a message that is safe
  /// to show a user. Every branch of the `requestEmailOtp` /
  /// `verifyEmailOtp` callables (see `functions/src/emailOtp.js`) throws a
  /// *typed* `HttpsError` with an already-readable message, so those are
  /// passed straight through; the codes handled explicitly here are the
  /// transport / platform failures where `e.message` is a bare token like
  /// `UNAVAILABLE`, `internal`, or `NOT_FOUND` and must never reach the UI.
  String _friendlyFunctionsMessage(
    String op,
    FirebaseFunctionsException e,
    int? retryAfterSeconds,
  ) {
    final verifying = op == 'verifyEmailOtp';
    switch (e.code) {
      case 'unauthenticated':
        return 'Your session expired. Sign out and back in, then try again.';
      case 'permission-denied':
        return 'You don\'t have permission to do that. Sign out and back in, '
            'then try again.';
      case 'not-found':
        // The callable itself is unreachable (not deployed / wrong region).
        return 'Email verification is temporarily unavailable. Please try '
            'again later.';
      case 'unavailable':
        return verifying
            ? 'Your code was correct but we couldn\'t reach the server. '
                'Please try again in a moment.'
            : 'Couldn\'t reach the server to send your code. Check your '
                'connection and try again.';
      case 'deadline-exceeded':
        return verifying
            ? 'This code has expired. Tap "Resend Code" to get a new one.'
            : 'The request timed out. Please try again.';
      case 'resource-exhausted':
        return e.message ??
            (retryAfterSeconds != null
                ? 'Too many attempts. Try again in '
                    '${(retryAfterSeconds / 60).ceil()} min.'
                : 'Too many attempts. Please wait a bit and try again.');
      case 'failed-precondition':
        // e.g. "Request a code first.", "Your account has no email address.",
        // "Email sending is not configured." — already user-readable.
        return e.message ?? 'Please request a fresh code and try again.';
      case 'invalid-argument':
        return e.message ?? 'Enter the 6-digit code.';
      case 'already-exists':
        return e.message ?? 'Your email is already verified.';
      case 'cancelled':
        return 'The request was cancelled. Please try again.';
      case 'internal':
      case 'unknown':
      default:
        // The callable's own ID-token exchange can surface an auth
        // internal-error wrapped as a functions `internal`.
        return verifying
            ? 'Something went wrong verifying your email. Please try again in '
                'a moment.'
            : 'Something went wrong sending your code. Please try again in a '
                'moment.';
    }
  }

  /// Explicit handling for a `FirebaseAuthException` reaching this layer —
  /// in practice `internal-error` from the ID-token refresh the callable
  /// does before the request. Full stack trace is logged (both to the
  /// console and, in release, to Crashlytics via `recordNonFatal`).
  EmailOtpException _mapAuth(
    String op,
    FirebaseAuthException e,
    StackTrace st,
  ) {
    _log('$op FAILED FirebaseAuthException '
        'code=${e.code} message=${e.message} plugin=${e.plugin}');
    debugPrintStack(stackTrace: st, label: '[EmailOtpService] $op auth error');
    AppErrorHandler.recordNonFatal(
      e,
      st,
      reason: 'EmailOtpService.$op (auth) [auth/${e.code}]',
    );
    switch (e.code) {
      case 'internal-error':
        return EmailOtpException(
          'Authentication is catching up — please wait a moment and try '
          'again.',
          code: 'internal-error',
        );
      case 'too-many-requests':
        return EmailOtpException(
          'Too many attempts from this device. Please wait a few minutes '
          'and try again.',
          code: e.code,
        );
      case 'network-request-failed':
        return EmailOtpException(
          'No connection. Check your internet and try again.',
          code: e.code,
        );
      case 'user-token-expired':
      case 'user-disabled':
      case 'user-not-found':
      case 'requires-recent-login':
        return EmailOtpException(
          'Your session is no longer valid. Sign out and back in, then try '
          'again.',
          code: e.code,
        );
      default:
        return EmailOtpException(
          e.message ?? 'Email verification failed. Please try again.',
          code: e.code,
        );
    }
  }

  EmailOtpException _mapUnknown(String op, Object e, StackTrace st) {
    _log('$op FAILED ${e.runtimeType}: $e');
    debugPrintStack(stackTrace: st, label: '[EmailOtpService] $op error');
    AppErrorHandler.recordNonFatal(e, st, reason: 'EmailOtpService.$op');
    return EmailOtpException(
      'Email verification failed. Please try again.',
    );
  }
}
