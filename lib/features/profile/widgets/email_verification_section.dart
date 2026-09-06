import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/services/email_otp_service.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/email_otp_provider.dart';
import '../../auth/providers/user_provider.dart';

/// Email verification via a 6-digit OTP emailed to the user (Cloud
/// Functions + Resend). Replaces the old Firebase email-verification
/// *link* flow. Structure mirrors [PhoneVerificationSection]: request a
/// code, then enter it, with a resend cooldown and a rate-limit timer.
class EmailVerificationSection extends ConsumerStatefulWidget {
  final String userId;
  final String email;

  const EmailVerificationSection({
    required this.userId,
    required this.email,
    super.key,
  });

  @override
  ConsumerState<EmailVerificationSection> createState() =>
      _EmailVerificationSectionState();
}

class _EmailVerificationSectionState
    extends ConsumerState<EmailVerificationSection> {
  final _otpController = TextEditingController();

  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  int _resendSeconds = 0;
  int _rateLimitSeconds = 0;
  Timer? _resendTimer;
  Timer? _rateLimitTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _rateLimitTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _startRateLimitTimer(int seconds) {
    _rateLimitTimer?.cancel();
    _resendTimer?.cancel();
    setState(() {
      _rateLimitSeconds = seconds;
      _resendSeconds = 0;
    });
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_rateLimitSeconds <= 1) {
        timer.cancel();
        setState(() => _rateLimitSeconds = 0);
      } else {
        setState(() => _rateLimitSeconds -= 1);
      }
    });
  }

  String _formatRetry(int totalSeconds) {
    if (totalSeconds >= 60) {
      final minutes = (totalSeconds / 60).ceil();
      return minutes <= 1 ? '1 minute' : '$minutes minutes';
    }
    return '$totalSeconds seconds';
  }

  Future<void> _sendCode() async {
    if (_resendSeconds > 0 || _rateLimitSeconds > 0 || _isSending) return;
    setState(() => _isSending = true);
    try {
      final result = await ref.read(emailOtpServiceProvider).requestOtp();
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _otpController.clear();
      });
      _startResendTimer(result.retryAfterSeconds);
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Code sent to ${widget.email}',
      );
    } on EmailOtpException catch (e) {
      if (!mounted) return;
      if (e.code == 'already-exists') {
        // Server says it's already verified — reconcile local state.
        await _markVerifiedLocally(showSnack: true);
        return;
      }
      if (e.code == 'resource-exhausted' && e.retryAfterSeconds != null) {
        _startRateLimitTimer(e.retryAfterSeconds!);
      }
      SnackBarHelper.showErrorSnackBar(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Could not send the code. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Enter the 6-digit code',
      );
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await ref.read(emailOtpServiceProvider).verifyOtp(code);
      await _markVerifiedLocally(showSnack: true);
    } on EmailOtpException catch (e) {
      if (!mounted) return;
      if (e.code == 'deadline-exceeded' || e.code == 'resource-exhausted') {
        setState(() {
          _codeSent = false;
          _otpController.clear();
        });
      }
      final suffix = e.attemptsLeft != null
          ? ' (${e.attemptsLeft} attempt${e.attemptsLeft == 1 ? '' : 's'} left)'
          : '';
      SnackBarHelper.showErrorSnackBar(context, message: '${e.message}$suffix');
    } catch (_) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Could not verify the code. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Pull the server-set `emailVerified` into the client and mirror it onto
  /// the Firestore user doc (same post-steps the link flow used).
  Future<void> _markVerifiedLocally({required bool showSnack}) async {
    await ref.read(authProvider.notifier).refreshEmailVerificationStatus();
    try {
      await ref.read(userRepositoryProvider).verifyEmail(widget.userId);
    } catch (_) {
      // The auth flag is the source of truth; the mirror is best-effort.
    }
    ref.invalidate(currentUserDetailProvider);
    _resendTimer?.cancel();
    if (mounted && showSnack) {
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Email verified successfully!',
      );
    }
    if (mounted) setState(() => _codeSent = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final emailVerified =
        ref.watch(authProvider.select((s) => s.user?.emailVerified)) == true;

    if (emailVerified) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded,
                color: AppTheme.accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email verified: ${widget.email}',
                style: AppFonts.plusJakarta(
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            StatusBadge(
              label: 'Verified',
              icon: Icons.verified,
              color: AppTheme.accentColor,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Verify Your Email',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
              StatusBadge(
                label: 'Unverified',
                icon: Icons.error_outline_rounded,
                color: AppTheme.warningColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _codeSent
                ? 'Enter the 6-digit code we emailed to ${widget.email}.'
                : 'We\'ll email a 6-digit code to ${widget.email}. Verify to '
                    'unlock reviews, bookmarks, and community.',
            style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textSecondary),
          ),
          if (_rateLimitSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Too many requests. Try again in ${_formatRetry(_rateLimitSeconds)}.',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColor,
                ),
              ),
            ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Enter code',
              hint: '6-digit code',
              controller: _otpController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.mark_email_unread_outlined,
              isRequired: true,
            ),
            if (_resendSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Resend available in $_resendSeconds s',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    color: tokens.textTertiary,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      (_isSending || _resendSeconds > 0 || _rateLimitSeconds > 0)
                          ? null
                          : _sendCode,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_codeSent ? 'Resend Code' : 'Send Code'),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.white,
                            ),
                          )
                        : const Text('Verify'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
