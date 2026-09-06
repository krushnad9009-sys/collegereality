import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/email_otp_service.dart';

/// Client for the custom email-OTP verification flow (Cloud Functions +
/// Resend). Stateless — the per-screen OTP flow state (code sent, resend
/// cooldown, verifying) lives in the widget, mirroring
/// `phoneAuthServiceProvider` / `PhoneVerificationSection`.
final emailOtpServiceProvider = Provider<EmailOtpService>((ref) {
  return EmailOtpService();
});
