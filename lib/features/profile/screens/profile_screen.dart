import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/sign_out.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../models/student_trust_model.dart';
import '../widgets/trust_score_card.dart';

/// The Profile "hub": a professional identity header plus clean, grouped
/// cards that link out to the profile editor, settings, and account
/// actions. The full editing form lives in [EditProfileScreen].
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and profile data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await ref.read(userRepositoryProvider).deleteUser(user.uid);
      await user.delete();
      if (context.mounted) await signOutAndRedirect(context, ref);
    } catch (_) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not delete account. Sign in again and retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final authUser = ref.watch(currentUserProvider);
    final userDetailAsync = ref.watch(currentUserDetailProvider);

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please log in to view your profile'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text('Profile', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: userDetailAsync.when(
        loading: () => const Center(child: ProfileHeaderSkeleton()),
        error: (e, _) => AsyncErrorView.fromError(
          e,
          onRetry: () => ref.invalidate(currentUserDetailProvider),
        ),
        data: (userDetail) {
          final displayName =
              (userDetail?.displayName?.trim().isNotEmpty ?? false)
              ? userDetail!.displayName!.trim()
              : (userDetail?.verifiedRealName?.trim().isNotEmpty ?? false)
              ? userDetail!.verifiedRealName!.trim()
              : (authUser.email ?? 'Student');

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              AppSpacing.lg,
              AppSpacing.pageH,
              AppSpacing.sectionLg,
            ),
            children: [
              AppReveal(
                delayMs: 0,
                child: _ProfileHubHeader(
                  photoUrl: userDetail?.photoURL,
                  displayName: displayName,
                  email: authUser.email ?? '',
                  verificationBadge: userDetail?.verificationBadge,
                  onEdit: () => context.push(RouteNames.editProfile),
                ),
              ),
              if (userDetail != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppReveal(
                  delayMs: 60,
                  child: TrustScoreCard(
                    trust: StudentTrustModel.fromUser(userDetail),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppReveal(
                delayMs: 110,
                child: _HubCard(
                  title: 'Account',
                  rows: [
                    PremiumListRow(
                      leadingIcon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Name, photo, college, and guide settings',
                      onTap: () => context.push(RouteNames.editProfile),
                    ),
                    PremiumListRow(
                      leadingIcon: Icons.tune_rounded,
                      title: 'App Settings',
                      subtitle: 'Appearance, notifications, and legal',
                      onTap: () => context.push(RouteNames.appSettings),
                    ),
                    PremiumListRow(
                      leadingIcon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Contact us or report a problem',
                      onTap: () => context.push(RouteNames.helpSupport),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppReveal(
                delayMs: 160,
                child: _SignOutTile(
                  onSignOut: () => signOutAndRedirect(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppReveal(
                delayMs: 210,
                child: PremiumCard(
                  radius: tokens.cardRadius,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: PremiumListRow(
                    leadingIcon: Icons.delete_forever_outlined,
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    title: 'Delete Account',
                    showChevron: false,
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A titled [PremiumCard] wrapping a list of [PremiumListRow]s separated by
/// thin dividers.
class _HubCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _HubCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final divided = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        divided.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(color: tokens.borderSubtle, height: 1),
          ),
        );
      }
      divided.add(rows[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppFonts.plusJakarta(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: tokens.textTertiary,
            ),
          ),
        ),
        PremiumCard(
          radius: tokens.cardRadius,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(children: divided),
        ),
      ],
    );
  }
}

/// Sleek left-aligned identity header: avatar with an edit badge, full name,
/// email, and a verification pill.
class _ProfileHubHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final String? verificationBadge;
  final VoidCallback onEdit;

  const _ProfileHubHeader({
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.verificationBadge,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'S');
    final isBadged =
        verificationBadge != null &&
        verificationBadge != VerificationConstants.badgeNone;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onEdit,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          initial,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tokens.surfaceElevated,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (isBadged)
                  VerificationBadgeWidget(badge: verificationBadge!)
                else
                  _GetVerifiedPill(
                    onTap: () => context.go(RouteNames.verification),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GetVerifiedPill extends StatelessWidget {
  final VoidCallback onTap;

  const _GetVerifiedPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 13,
                color: tokens.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Get verified',
                style: AppFonts.plusJakarta(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sign-out row with a confirm dialog and an animated in-progress state:
/// while `signOut` runs the row tints, the icon cross-fades to a spinner,
/// and further taps are ignored.
class _SignOutTile extends StatefulWidget {
  final Future<void> Function() onSignOut;

  const _SignOutTile({required this.onSignOut});

  @override
  State<_SignOutTile> createState() => _SignOutTileState();
}

class _SignOutTileState extends State<_SignOutTile> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Yes, Sign Out',
      cancelText: 'Cancel',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onSignOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final danger = Colors.red.shade400;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _busy ? danger.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
        child: PremiumListRow(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _busy
                    ? SizedBox(
                        key: const ValueKey('spinner'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(danger),
                        ),
                      )
                    : Icon(
                        Icons.logout_rounded,
                        key: const ValueKey('icon'),
                        color: tokens.textSecondary,
                      ),
              ),
            ),
          ),
          title: _busy ? 'Signing out…' : 'Sign Out',
          titleColor: _busy ? danger : null,
          showChevron: false,
          onTap: _busy ? null : _handleTap,
        ),
      ),
    );
  }
}
