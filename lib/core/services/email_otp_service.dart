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
    _log('$op FAILED FirebaseFunctionsException '
        'code=${e.code} message=${e.message} details=$details\n$st');
    AppErrorHandler.recordNonFatal(e, st, reason: 'EmailOtpService.$op');
    // The callable's own token exchange can surface an auth internal-error
    // wrapped as a functions `internal`.
    if (e.code == 'internal') {
      return EmailOtpException(
        'Something went wrong verifying your email. Please try again in a '
        'moment.',
        code: 'internal-error',
      );
    }
    return EmailOtpException(
      e.message ?? 'Email verification failed. Please try again.',
      code: e.code,
      retryAfterSeconds: (details['retryAfterSeconds'] as num?)?.toInt(),
      attemptsLeft: (details['attemptsLeft'] as num?)?.toInt(),
    );
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
    AppErrorHandler.recordNonFatal(e, st, reason: 'EmailOtpService.$op (auth)');
    if (e.code == 'internal-error') {
      return EmailOtpException(
        'Authentication is catching up — please wait a moment and try '
        'again.',
        code: 'internal-error',
      );
    }
    return EmailOtpException(
      e.message ?? 'Email verification failed. Please try again.',
      code: e.code,
    );
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
