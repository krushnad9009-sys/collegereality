import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;
  String? _pendingPhone;
  ConfirmationResult? _webConfirmationResult;
  RecaptchaVerifier? _recaptchaVerifier;
  Future<void>? _sendOtpInFlight;

  String? get verificationId => _verificationId;
  String? get pendingPhone => _pendingPhone;

  /// Each web OTP attempt needs a fresh reCAPTCHA verifier. Reusing one causes
  /// Firebase's internal verify() future to be completed twice.
  RecaptchaVerifier _resetAndCreateWebRecaptcha() {
    _recaptchaVerifier?.clear();
    _recaptchaVerifier = RecaptchaVerifier(
      auth: FirebaseAuthPlatform.instance,
      container: 'recaptcha-container',
      size: RecaptchaVerifierSize.compact,
      theme: RecaptchaVerifierTheme.light,
    );
    return _recaptchaVerifier!;
  }

  Future<void> sendOtp(String phoneNumber) async {
    if (_sendOtpInFlight != null) {
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

    if (kIsWeb) {
      final user = _auth.currentUser;
      if (user == null) {
        throw PhoneAuthException('You must be logged in to verify your phone');
      }

      final verifier = _resetAndCreateWebRecaptcha();
      try {
        _webConfirmationResult = await user.linkWithPhoneNumber(
          formatted,
          verifier,
        );
      } catch (e) {
        throw _mapError(e);
      }
      return;
    }

    final completer = Completer<void>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formatted,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _linkPhoneCredential(credential);
            _completeOnce(completer);
          } catch (e) {
            _completeOnce(completer, error: _mapError(e));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _completeOnce(completer, error: _mapError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _completeOnce(completer);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
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
    if (kIsWeb) {
      if (_webConfirmationResult == null) {
        throw PhoneAuthException('Please request OTP first');
      }
      await _webConfirmationResult!.confirm(smsCode);
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
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
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
      rethrow;
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
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-phone-number':
          return PhoneAuthException('Invalid phone number format');
        case 'too-many-requests':
          return PhoneAuthException(
            'Too many OTP requests. Please try again in 30 minutes.',
            code: 'too-many-requests',
            retryAfter: const Duration(minutes: 30),
          );
        case 'quota-exceeded':
          return PhoneAuthException(
            'Too many verification attempts. Please try again in 30 minutes.',
            code: 'quota-exceeded',
            retryAfter: const Duration(minutes: 30),
          );
        case 'invalid-verification-code':
          return PhoneAuthException('Invalid OTP. Please try again.');
        case 'session-expired':
          return PhoneAuthException('OTP expired. Request a new code.');
        default:
          return PhoneAuthException(
            'Phone verification failed. Please try again.',
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
