import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/sign_out.dart';
import 'legal_screens.dart';

/// Blocking, mandatory post-login onboarding gate. The router shows this
/// whenever the signed-in user's `hasAcceptedTerms` flag is not `true`, and
/// the user cannot reach any other route (public or protected) until they
/// tap "I Agree & Accept Terms" (or sign out).
class TermsGateScreen extends ConsumerStatefulWidget {
  const TermsGateScreen({super.key});

  @override
  ConsumerState<TermsGateScreen> createState() => _TermsGateScreenState();
}

class _TermsGateScreenState extends ConsumerState<TermsGateScreen> {
  bool _isSaving = false;

  Future<void> _acceptAndContinue() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      await signOutAndRedirect(context, ref);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).acceptTerms(uid);
      ref.invalidate(currentUserDetailProvider);
      // Wait for the refreshed doc so the router's redirect sees
      // `hasAcceptedTerms: true` on the very next navigation.
      await ref.read(currentUserDetailProvider.future);
      if (mounted) context.go(RouteNames.home);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: FirestoreErrorUtils.userMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    // Hard gate — the back gesture/button must not escape it.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: tokens.surfaceMuted,
        body: SafeArea(
          child: Column(
            children: [
              AppReveal(
                delayMs: 0,
                slideFrom: 0.12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageH,
                    AppSpacing.xl,
                    AppSpacing.pageH,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.gavel_rounded, color: primary),
                          )
                          .animate()
                          .scaleXY(
                            begin: 0.6,
                            end: 1,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 250.ms),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Terms & Conditions',
                        style: AppFonts.plusJakarta(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Please read and accept our Terms & Conditions to '
                        'start using College Reality.',
                        style: AppFonts.plusJakarta(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AppReveal(
                  delayMs: 120,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageH,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(tokens.cardRadius),
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Scrollbar(
                      child: ListView(
                        primary: true,
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        children: [
                          Text(
                            termsAndConditionsIntro,
                            style: AppFonts.plusJakarta(
                              fontSize: 13.5,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          for (final section in termsOfServiceSections) ...[
                            Text(
                              section.heading,
                              style: AppFonts.plusJakarta(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              section.body,
                              style: AppFonts.plusJakarta(
                                fontSize: 13.5,
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                                color: tokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppReveal(
                delayMs: 220,
                slideFrom: 0.15,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageH,
                    AppSpacing.md,
                    AppSpacing.pageH,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'I Agree & Accept Terms',
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _acceptAndContinue,
                      ),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => signOutAndRedirect(context, ref),
                        child: Text(
                          'Not now, sign out',
                          style: AppFonts.plusJakarta(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
