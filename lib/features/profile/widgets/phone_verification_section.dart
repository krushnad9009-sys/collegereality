import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../auth/providers/phone_auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/validation_util.dart';

class PhoneVerificationSection extends ConsumerStatefulWidget {
  final String userId;
  final String? currentPhone;
  final bool isPhoneVerified;
  final ValueChanged<String> onVerified;

  const PhoneVerificationSection({
    required this.userId,
    required this.currentPhone,
    required this.isPhoneVerified,
    required this.onVerified,
    super.key,
  });

  @override
  ConsumerState<PhoneVerificationSection> createState() =>
      _PhoneVerificationSectionState();
}

class _PhoneVerificationSectionState
    extends ConsumerState<PhoneVerificationSection> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  int _resendSeconds = 0;
  int _rateLimitSeconds = 0;
  Timer? _resendTimer;
  Timer? _rateLimitTimer;

  static const _resendCooldown = 60;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentPhone ?? '';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _rateLimitTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startRateLimitTimer(Duration retryAfter) {
    _rateLimitTimer?.cancel();
    _resendTimer?.cancel();
    setState(() {
      _rateLimitSeconds = retryAfter.inSeconds;
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

  String _formatRetryDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).ceil();
    if (minutes <= 1) return '1 minute';
    return '$minutes minutes';
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldown);
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

  Future<void> _persistPhoneVerification() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final normalized =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;

    await ref.read(userRepositoryProvider).verifyPhone(
          widget.userId,
          phone: normalized,
        );
    ref.invalidate(currentUserDetailProvider);
    widget.onVerified(normalized);
  }

  Future<void> _sendOtp() async {
    if (_resendSeconds > 0 || _rateLimitSeconds > 0) return;

    final phoneError = ValidationUtil.validatePhone(_phoneController.text);
    if (phoneError != null) {
      SnackBarHelper.showErrorSnackBar(context, message: phoneError);
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(phoneAuthServiceProvider)
          .sendOtp(_phoneController.text.trim());

      final phoneService = ref.read(phoneAuthServiceProvider);
      if (phoneService.isPhoneLinkedOnAccount) {
        await _persistPhoneVerification();
        if (mounted) {
          SnackBarHelper.showSuccessSnackBar(
            context,
            message: 'Phone verified successfully!',
          );
        }
        return;
      }

      setState(() {
        _otpSent = true;
        _otpController.clear();
      });
      _startResendTimer();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: _resendSeconds == _resendCooldown
              ? 'OTP sent to +91${_phoneController.text.trim()}'
              : 'OTP resent successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is PhoneAuthException &&
            (e.code == 'too-many-requests' || e.code == 'quota-exceeded')) {
          _startRateLimitTimer(e.retryAfter ?? const Duration(minutes: 30));
          SnackBarHelper.showErrorSnackBar(
            context,
            message:
                'Too many OTP attempts. Try again in ${_formatRetryDuration(_rateLimitSeconds)}.',
          );
        } else {
          SnackBarHelper.showErrorSnackBar(
            context,
            message: e is PhoneAuthException
                ? e.message
                : 'Could not send OTP. Please try again.',
          );
        }
        // Debug builds only: `verificationFailed` (and every other OTP-send
        // failure) is otherwise only visible in `debugPrint` logs. Put the
        // exact FirebaseAuthException code/message/fix on screen so a local
        // "SMS never arrives" repro is diagnosable without a log console.
        if (kDebugMode && e is PhoneAuthException) {
          _showDebugPhoneAuthErrorDialog(e);
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showDebugPhoneAuthErrorDialog(PhoneAuthException e) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Phone Auth failed (debug)'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _debugRow('code', e.code ?? '(none)'),
              _debugRow('message', e.rawMessage ?? e.message),
              if (e.hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  'FIX',
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  e.hint!,
                  style: AppFonts.plusJakarta(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: AppFonts.plusJakarta(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _changeNumber() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _resendSeconds = 0;
      _otpController.clear();
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Enter the 6-digit OTP',
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await ref.read(phoneAuthServiceProvider).verifyOtpAndLink(
            _otpController.text.trim(),
          );
      await _persistPhoneVerification();
      _resendTimer?.cancel();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Phone verified successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: e is PhoneAuthException
              ? e.message
              : 'Could not verify OTP. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (widget.isPhoneVerified) {
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
            const Icon(Icons.phone_android, color: AppTheme.accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Phone verified: +91 ${widget.currentPhone ?? ''}',
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
        color: AppTheme.secondaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phone Verification',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              StatusBadge(
                label: 'Unverified',
                icon: Icons.error_outline_rounded,
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your mobile number using a one-time password (OTP).',
            style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 12),
          PhoneTextField(
            label: 'Mobile Number',
            hint: '10-digit number',
            controller: _phoneController,
            validator: ValidationUtil.validatePhone,
          ),
          if (_rateLimitSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Too many attempts. Try again in ${_formatRetryDuration(_rateLimitSeconds)}.',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColor,
                ),
              ),
            ),
          if (_otpSent) ...[
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Enter OTP',
              hint: '6-digit code',
              controller: _otpController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.sms_outlined,
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _changeNumber,
                child: const Text('Change number'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_isSending || _resendSeconds > 0 || _rateLimitSeconds > 0)
                      ? null
                      : _sendOtp,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.white,
                            ),
                          )
                        : const Text('Verify OTP'),
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
