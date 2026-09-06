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

  Future<EmailOtpRequestResult> requestOtp() async {
    try {
      _log('requestEmailOtp: calling');
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
      throw _map('requestEmailOtp', e, st);
    }
  }

  /// Verifies [code]. On success the Firebase Auth user is `emailVerified`
  /// server-side — the caller should then `reloadUser()` to observe it.
  Future<void> verifyOtp(String code) async {
    try {
      _log('verifyEmailOtp: calling');
      await _functions
          .httpsCallable('verifyEmailOtp')
          .call<Map<dynamic, dynamic>>({'code': code});
      _log('verifyEmailOtp: ok');
    } on FirebaseFunctionsException catch (e, st) {
      throw _map('verifyEmailOtp', e, st);
    }
  }

  EmailOtpException _map(
    String op,
    FirebaseFunctionsException e,
    StackTrace st,
  ) {
    final details = e.details is Map
        ? Map<String, dynamic>.from(e.details as Map)
        : const <String, dynamic>{};
    _log(
      '$op FAILED code=${e.code} message=${e.message} details=$details',
    );
    AppErrorHandler.recordNonFatal(e, st, reason: 'EmailOtpService.$op');
    return EmailOtpException(
      e.message ?? 'Email verification failed. Please try again.',
      code: e.code,
      retryAfterSeconds: (details['retryAfterSeconds'] as num?)?.toInt(),
      attemptsLeft: (details['attemptsLeft'] as num?)?.toInt(),
    );
  }
}
