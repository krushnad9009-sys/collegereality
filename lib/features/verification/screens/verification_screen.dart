import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../widgets/document_upload_section.dart';
import '../widgets/verification_badge_widget.dart';
import '../../profile/widgets/phone_verification_section.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final userAsync = ref.watch(currentUserDetailProvider);

    if (authUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.profile),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.verificationBadge != VerificationConstants.badgeNone)
                  Center(
                    child: Column(
                      children: [
                        VerificationBadgeWidget(
                          badge: user.verificationBadge,
                          iconSize: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your identity is verified on College Reality.',
                          style: GoogleFonts.poppins(color: AppTheme.gray600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Secure verification only — no community or peer verification. '
                      'Your phone, email, and documents stay private on your public profile.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.gray700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!authUser.emailVerified)
                    _EmailSection(userId: user.uid)
                  else
                    _VerifiedBanner(label: 'Email verified'),
                  const SizedBox(height: 16),
                  PhoneVerificationSection(
                    userId: user.uid,
                    currentPhone: user.phone,
                    isPhoneVerified: user.isPhoneVerified,
                    onVerified: (_) {
                      ref.invalidate(currentUserDetailProvider);
                    },
                  ),
                  const SizedBox(height: 24),
                  DocumentUploadSection(user: user),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmailSection extends ConsumerWidget {
  final String userId;

  const _EmailSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email verification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await ref.read(authProvider.notifier).sendEmailVerification();
                    if (context.mounted) {
                      SnackBarHelper.showSuccessSnackBar(
                        context,
                        message: 'Verification email sent.',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackBarHelper.showErrorSnackBar(
                        context,
                        message: e.toString(),
                      );
                    }
                  }
                },
                child: const Text('Resend Email'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final verified = await ref
                      .read(authProvider.notifier)
                      .refreshEmailVerificationStatus();
                  if (!context.mounted) return;
                  if (verified) {
                    await ref.read(userRepositoryProvider).verifyEmail(userId);
                    ref.invalidate(currentUserDetailProvider);
                    if (!context.mounted) return;
                    SnackBarHelper.showSuccessSnackBar(
                      context,
                      message: 'Email verified!',
                    );
                  } else {
                    SnackBarHelper.showInfoSnackBar(
                      context,
                      message: 'Email not verified yet. Check your inbox.',
                    );
                  }
                },
                child: const Text('I Verified'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerifiedBanner extends StatelessWidget {
  final String label;

  const _VerifiedBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppTheme.accentColor),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
