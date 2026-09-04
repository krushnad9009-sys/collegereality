import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

import 'crashlytics_service.dart';

/// Hostname check for localhost web dev (testable without Firebase).
bool isLocalWebHostName(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '[::1]';
}

bool get isLocalWebHost => kIsWeb && isLocalWebHostName(Uri.base.host);

class PhoneAuthService {
  static const _webLinkTimeout = Duration(seconds: 120);
  static const _logTag = '[PhoneAuthService]';

  /// When true, Firebase phone-auth "app verification" — Play Integrity /
  /// SafetyNet on Android, reCAPTCHA on web — is disabled so the **test
  /// phone numbers** registered in Firebase Console
  /// (Authentication → Sign-in method → Phone → "Phone numbers for
  /// testing") return their pre-set code with **no real SMS** and no
  /// reCAPTCHA challenge.
  ///
  /// Defaults **OFF** — the normal flow dispatches a real SMS. Turn it on
  /// only when you are deliberately testing against Console test numbers:
  /// `--dart-define=PHONE_AUTH_DISABLE_APP_VERIFICATION=true` (debug builds
  /// only; the `kDebugMode &&` guard forces it off in release regardless).
  static const bool disableAppVerificationForTesting = kDebugMode &&
      bool.fromEnvironment(
        'PHONE_AUTH_DISABLE_APP_VERIFICATION',
        defaultValue: false,
      );

  /// Forces the **reCAPTCHA** verification fallback on Android instead of
  /// the Play Integrity / SafetyNet attestation path.
  ///
  /// Defaults ON for Android debug builds: a locally-built debug APK whose
  /// signing SHA-256 isn't registered in Firebase Console fails attestation
  /// (`invalid-app-credential` / `missing-client-identifier`) and the
  /// automatic fallback is unreliable on some devices/emulators — so real
  /// OTP SMS never gets dispatched. Forcing reCAPTCHA makes it work with
  /// zero console setup. Disable with
  /// `--dart-define=PHONE_AUTH_FORCE_RECAPTCHA=false` once a real SHA-256
  /// is registered. No-op on web/iOS and in release.
  static bool get forceRecaptchaFlowForDebug =>
      kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      const bool.fromEnvironment(
        'PHONE_AUTH_FORCE_RECAPTCHA',
        defaultValue: true,
      );

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;
  String? _pendingPhone;
  ConfirmationResult? _webConfirmationResult;
  RecaptchaVerifier? _recaptchaVerifier;
  Future<void>? _sendOtpInFlight;
  bool _authSettingsApplied = false;

  String? get verificationId => _verificationId;
  String? get pendingPhone => _pendingPhone;

  void _log(String message) {
    debugPrint('$_logTag $message');
  }

  void _logException(Object error, StackTrace stackTrace, {String? step}) {
    final prefix = step == null ? 'Exception' : 'Exception at $step';
    if (error is FirebaseAuthException) {
      final hint = _diagnosticHint(error.code);
      _log(
        '$prefix: FirebaseAuthException '
        'code=${error.code} '
        'message=${error.message} '
        'plugin=${error.plugin}'
        '${hint == null ? '' : '\n  ↳ FIX: $hint'}\n$stackTrace',
      );
    } else {
      _log('$prefix: ${error.runtimeType}: $error\n$stackTrace');
    }
    // No-op in debug and on web (see CrashlyticsService); in a release
    // native build this puts the exact code/message behind every
    // user-facing "OTP failed" message so the root cause is visible
    // without a repro.
    CrashlyticsService.recordError(
      error,
      stackTrace,
      reason: 'PhoneAuth${step == null ? '' : ' ($step)'}',
    );
  }

  /// Actionable next step for the FirebaseAuthException codes that mean a
  /// project/build **misconfiguration** rather than user error — surfaced
  /// in the log so "OTP just fails" is self-diagnosing during local dev.
  String? _diagnosticHint(String code) {
    switch (code) {
      case 'invalid-app-credential':
      case 'missing-client-identifier':
        return 'Android app attestation failed. Add this build\'s SHA-1 AND '
            'SHA-256 to Firebase Console -> Project Settings -> your Android '
            'app, re-download google-services.json, and enable the Play '
            'Integrity API. Or (default in debug) let PHONE_AUTH_FORCE_'
            'RECAPTCHA=true use the reCAPTCHA fallback instead.';
      case 'captcha-check-failed':
        return 'reCAPTCHA token rejected. Web: add this origin under '
            'Authentication -> Settings -> Authorized domains, and check the '
            'API key HTTP-referrer restrictions in Google Cloud Console.';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'SMS/verification quota hit for this project/device/number. '
            'Use a Firebase Console test phone number (no quota, no SMS) for '
            'local testing, or wait ~30 minutes.';
      case 'operation-not-allowed':
        return 'Phone provider disabled, or SMS region policy blocks this '
            'country. Firebase Console -> Authentication -> Sign-in method -> '
            'Phone (enable), and -> Settings -> SMS region policy (allow the '
            'target country, e.g. +91 India).';
      case 'billing-not-enabled':
        return 'Phone Auth on this project requires the Blaze plan. Upgrade '
            'billing, or use a Console test phone number.';
      case 'unauthorized-domain':
        return 'This web origin is not in Authentication -> Settings -> '
            'Authorized domains.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Authentication '
            'with the provided API key. Check the API key restrictions and '
            'that google-services.json / GoogleService-Info.plist matches '
            'this bundle/package id.';
      default:
        return null;
    }
  }

  /// Applies phone-auth [FirebaseAuth.setSettings] flags exactly once per
  /// service instance, before the first OTP request:
  ///  * [disableAppVerificationForTesting] — Console test numbers only.
  ///  * [forceRecaptchaFlowForDebug] — Android debug reCAPTCHA fallback so
  ///    real SMS dispatches without a registered SHA-256.
  /// Any failure here is logged but non-fatal — the request still proceeds.
  Future<void> _applyAuthSettingsOnce() async {
    if (_authSettingsApplied) return;
    _authSettingsApplied = true;

    final disableAppVerification = disableAppVerificationForTesting;
    final forceRecaptcha = forceRecaptchaFlowForDebug;

    if (!disableAppVerification && !forceRecaptcha) {
      _log(
        'Auth settings: default real app-verification path '
        '(kIsWeb=$kIsWeb debug=$kDebugMode platform=$defaultTargetPlatform).',
      );
      return;
    }

    try {
      if (kIsWeb) {
        // firebase_auth_web's setSettings only supports this flag.
        await _auth.setSettings(
          appVerificationDisabledForTesting: disableAppVerification,
        );
      } else {
        await _auth.setSettings(
          appVerificationDisabledForTesting: disableAppVerification,
          forceRecaptchaFlow: forceRecaptcha ? true : null,
        );
      }
      _log(
        'Auth settings applied: '
        'appVerificationDisabledForTesting=$disableAppVerification, '
        'forceRecaptchaFlow=${!kIsWeb && forceRecaptcha}. '
        '${disableAppVerification ? "ONLY Console test phone numbers will "
            "receive a code (no real SMS). " : ""}'
        '${!kIsWeb && forceRecaptcha ? "Android uses the reCAPTCHA fallback "
            "(a browser challenge) instead of Play Integrity/SafetyNet. " : ""}',
      );
    } catch (e, st) {
      _logException(e, st, step: 'setSettings');
    }
  }

  /// Each web OTP attempt needs a fresh reCAPTCHA verifier. Reusing one causes
  /// Firebase's internal verify() future to be completed twice.
  RecaptchaVerifier _resetAndCreateWebRecaptcha() {
    _log(
      'Before creating RecaptchaVerifier '
      '(host=${Uri.base.host}, scheme=${Uri.base.scheme})',
    );
    _recaptchaVerifier?.clear();
    _recaptchaVerifier = RecaptchaVerifier(
      auth: FirebaseAuthPlatform.instance,
      onSuccess: () => _log('reCAPTCHA onSuccess callback'),
      onError: (error) => _log('reCAPTCHA onError callback: $error'),
      onExpired: () => _log('reCAPTCHA onExpired callback'),
    );
    _log('After creating RecaptchaVerifier (invisible, no DOM container)');
    return _recaptchaVerifier!;
  }

  Future<void> sendOtp(String phoneNumber) async {
    if (_sendOtpInFlight != null) {
      _log('sendOtp skipped — request already in flight');
      return _sendOtpInFlight!;
    }

    final operation = _sendOtpOnce(phoneNumber);
    _sendOtpInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_sendOtpInFlight, operation)) {
        _sendOtpInFlight = null;
      }
    }
  }

  Future<void> _sendOtpOnce(String phoneNumber) async {
    final formatted = _formatPhone(phoneNumber);
    _pendingPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (_pendingPhone!.startsWith('91') && _pendingPhone!.length == 12) {
      _pendingPhone = _pendingPhone!.substring(2);
    }

    _log('sendOtp started for $formatted (raw input=$phoneNumber)');

    await _applyAuthSettingsOnce();
    _log(
      'sendOtp config: kIsWeb=$kIsWeb kDebugMode=$kDebugMode '
      'appVerificationDisabledForTesting=$disableAppVerificationForTesting '
      'forceRecaptchaFlowForDebug=$forceRecaptchaFlowForDebug '
      'host=${kIsWeb ? Uri.base.host : "(native)"}',
    );

    if (kIsWeb) {
      await _sendOtpWeb(formatted);
      return;
    }

    await _sendOtpNative(formatted);
  }

  Future<void> _sendOtpWeb(String formatted) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw PhoneAuthException('You must be logged in to verify your phone');
    }

    _log('Web path: currentUser uid=${user.uid} email=${user.email}');
    _webConfirmationResult = null;

    final verifier = _resetAndCreateWebRecaptcha();
    try {
      _log('Before RecaptchaVerifier.render()');
      final widgetId = await verifier.render().timeout(
        _webLinkTimeout,
        onTimeout: () {
          throw PhoneAuthException(
            'reCAPTCHA timed out. Please try again.',
            code: 'recaptcha-timeout',
          );
        },
      );
      _log('After Recaptcha loads — render complete, widgetId=$widgetId');

      _log('Before linkWithPhoneNumber($formatted)');
      _webConfirmationResult = await user
          .linkWithPhoneNumber(formatted, verifier)
          .timeout(
        _webLinkTimeout,
        onTimeout: () {
          throw PhoneAuthException(
            'Phone verification timed out waiting for SMS. Please try again.',
            code: 'link-timeout',
          );
        },
      );
      _log('After linkWithPhoneNumber — ConfirmationResult received');
    } catch (e, st) {
      _webConfirmationResult = null;
      _logException(e, st, step: 'linkWithPhoneNumber/render');
      throw _mapError(e);
    }
  }

  Future<void> _sendOtpNative(String formatted) async {
    final completer = Completer<void>();

    _log('Before verifyPhoneNumber($formatted)');
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formatted,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _log('verificationCompleted callback — auto-retrieval/link attempt');
          try {
            await _linkPhoneCredential(credential);
            _log('verificationCompleted — phone linked successfully');
            _completeOnce(completer);
          } catch (e, st) {
            _logException(e, st, step: 'verificationCompleted');
            // Fall back to manual OTP entry via codeSent.
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logException(
            e,
            e.stackTrace ?? StackTrace.current,
            step: 'verifyPhoneNumber.verificationFailed',
          );
          _completeOnce(completer, error: _mapError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _log(
            'codeSent callback: verificationId=${verificationId.substring(0, 8)}… '
            'resendToken=${resendToken != null}',
          );
          _verificationId = verificationId;
          _resendToken = resendToken;
          _completeOnce(completer);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _log(
            'codeAutoRetrievalTimeout callback: '
            'verificationId=${verificationId.substring(0, 8)}…',
          );
          _verificationId = verificationId;
        },
      );
      _log('After verifyPhoneNumber() — awaiting callbacks');
    } catch (e, st) {
      _logException(e, st, step: 'verifyPhoneNumber');
      _completeOnce(completer, error: _mapError(e));
    }

    return completer.future;
  }

  void _completeOnce(Completer<void> completer, {Object? error}) {
    if (completer.isCompleted) return;
    if (error != null) {
      completer.completeError(error);
    } else {
      completer.complete();
    }
  }

  Future<void> verifyOtpAndLink(String smsCode) async {
    _log('verifyOtpAndLink started (code length=${smsCode.length})');
    if (kIsWeb) {
      if (_webConfirmationResult == null) {
        throw PhoneAuthException('Please request OTP first');
      }
      try {
        _log('Before ConfirmationResult.confirm()');
        await _webConfirmationResult!.confirm(smsCode);
        _log('After ConfirmationResult.confirm() — success');
      } catch (e, st) {
        _logException(e, st, step: 'ConfirmationResult.confirm');
        throw _mapError(e);
      }
      await _auth.currentUser?.reload();
      return;
    }

    if (_verificationId == null) {
      throw PhoneAuthException('Please request OTP first');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    await _linkPhoneCredential(credential);
    await _auth.currentUser?.reload();
  }

  bool get isPhoneLinkedOnAccount {
    final phone = _auth.currentUser?.phoneNumber;
    return phone != null && phone.isNotEmpty;
  }

  Future<void> _linkPhoneCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw PhoneAuthException('You must be logged in to verify your phone');
    }

    try {
      _log('Before linkWithCredential() uid=${user.uid}');
      await user.linkWithCredential(credential);
      _log('After linkWithCredential() — success');
    } on FirebaseAuthException catch (e, st) {
      _logException(e, st, step: 'linkWithCredential');
      if (e.code == 'provider-already-linked') {
        return;
      }
      if (e.code == 'credential-already-in-use') {
        throw PhoneAuthException(
          'This phone number is already linked to another account',
        );
      }
      if (e.code == 'invalid-verification-code') {
        throw PhoneAuthException('Invalid OTP. Please try again.');
      }
      throw _mapError(e);
    }
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (phone.startsWith('+')) return phone;
    return '+91$digits';
  }

  PhoneAuthException _mapError(Object e) {
    if (e is PhoneAuthException) return e;

    final text = e.toString().toLowerCase();
    if (text.contains('future already completed') ||
        text.contains('converted future')) {
      return PhoneAuthException(
        'Phone verification was interrupted. Please try again.',
        code: 'session-reset',
      );
    }

    if (e is TimeoutException) {
      return PhoneAuthException(
        'Phone verification timed out. Please try again.',
        code: 'timeout',
      );
    }

    if (e is FirebaseAuthException) {
      _log(
        'FirebaseAuthException mapped: code=${e.code} message=${e.message}',
      );
      switch (e.code) {
        case 'invalid-phone-number':
          return PhoneAuthException('Invalid phone number format', code: e.code);
        case 'too-many-requests':
          return PhoneAuthException(
            e.message ??
                'Too many OTP requests. Please try again in 30 minutes.',
            code: e.code,
            retryAfter: const Duration(minutes: 30),
          );
        case 'quota-exceeded':
          return PhoneAuthException(
            e.message ??
                'Too many verification attempts. Please try again in 30 minutes.',
            code: e.code,
            retryAfter: const Duration(minutes: 30),
          );
        case 'invalid-verification-code':
          return PhoneAuthException('Invalid OTP. Please try again.', code: e.code);
        case 'session-expired':
          return PhoneAuthException('OTP expired. Request a new code.', code: e.code);
        case 'operation-not-allowed':
          return PhoneAuthException(
            e.message ??
                'Phone authentication is not enabled for this region. '
                    'Enable India (+91) under Firebase Console → Authentication → '
                    'Settings → SMS region policy.',
            code: e.code,
          );
        case 'captcha-check-failed':
          return PhoneAuthException(
            e.message ?? 'reCAPTCHA verification failed. Please try again.',
            code: e.code,
          );
        case 'invalid-app-credential':
          return PhoneAuthException(
            e.message ?? 'Invalid app credentials for phone authentication.',
            code: e.code,
          );
        case 'unauthorized-domain':
          return PhoneAuthException(
            e.message ?? 'This domain is not authorized for phone authentication.',
            code: e.code,
          );
        default:
          return PhoneAuthException(
            e.message ?? 'Phone verification failed. Please try again.',
            code: e.code,
          );
      }
    }
    return PhoneAuthException('Phone verification failed. Please try again.');
  }

  void dispose() {
    _sendOtpInFlight = null;
    _webConfirmationResult = null;
    _recaptchaVerifier?.clear();
    _recaptchaVerifier = null;
  }
}

class PhoneAuthException implements Exception {
  final String message;
  final String? code;
  final Duration? retryAfter;

  PhoneAuthException(
    this.message, {
    this.code,
    this.retryAfter,
  });

  @override
  String toString() => message;
}
