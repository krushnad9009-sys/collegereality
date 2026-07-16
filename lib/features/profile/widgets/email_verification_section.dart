import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';

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
  bool _isSending = false;
  bool _isChecking = false;

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Verification email sent to ${widget.email}',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final verified =
          await ref.read(authProvider.notifier).refreshEmailVerificationStatus();
      if (!mounted) return;
      if (verified) {
        await ref.read(userRepositoryProvider).verifyEmail(widget.userId);
        ref.invalidate(currentUserDetailProvider);
        if (!mounted) return;
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Email verified successfully!',
        );
      } else {
        SnackBarHelper.showInfoSnackBar(
          context,
          message: 'Not verified yet. Open the link in your inbox, then tap Check again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.emailVerified == true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Email verified: ${widget.email}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.verified, color: AppTheme.accentColor, size: 18),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Your Email',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We sent a link to ${widget.email}. Verify to unlock reviews, bookmarks, and community.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSending ? null : _sendVerificationEmail,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Email'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  child: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ),
                        )
                      : const Text('I Verified'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
