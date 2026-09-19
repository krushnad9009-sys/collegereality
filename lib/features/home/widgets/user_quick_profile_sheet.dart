import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';

/// Opens the simplified "Quick Profile" sheet shown from the Home avatar.
///
/// Deliberately not a menu: navigation lives in [HomeNavigationDrawer]. This
/// only shows who you are, how to reach you, your verification state, and a
/// way to edit.
Future<void> showUserQuickProfileSheet(BuildContext context) {
  // Captured before the sheet opens: the sheet's own context is gone by the
  // time navigation runs after it has been popped.
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => UserQuickProfileSheet(
      onNavigate: (route) {
        Navigator.of(sheetContext).pop();
        router.go(route);
      },
    ),
  );
}

enum _BadgeState { verified, pending, resubmit, unverified }

class UserQuickProfileSheet extends ConsumerWidget {
  /// Called with the destination route; the caller decides how to close the
  /// sheet and navigate.
  final void Function(String route) onNavigate;

  const UserQuickProfileSheet({required this.onNavigate, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final firebaseUser = ref.watch(currentUserProvider);
    final detail = ref.watch(currentUserDetailProvider).valueOrNull;

    final accountName = _firstNonEmpty([
          detail?.verifiedRealName,
          detail?.displayName,
          firebaseUser?.displayName,
        ]) ??
        'Student';
    // The name other students see -- can be an anonymous alias, so it is
    // shown separately from the account name rather than replacing it.
    final publicName = detail?.effectivePublicDisplayName;
    final email = _firstNonEmpty([detail?.email, firebaseUser?.email]);
    final phone = _firstNonEmpty([detail?.phone, firebaseUser?.phoneNumber]);
    final photoUrl = _firstNonEmpty([detail?.photoURL, firebaseUser?.photoURL]);
    final badge = _badgeStateFor(detail);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: _ProfileAvatar(
                photoUrl: photoUrl,
                name: accountName,
                verified: badge == _BadgeState.verified,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              accountName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakarta(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: tokens.textPrimary,
              ),
            ),
            if (publicName != null &&
                publicName.isNotEmpty &&
                publicName != accountName) ...[
              const SizedBox(height: 2),
              Text(
                'Shown to others as $publicName',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: email,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Mobile',
              value: phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            _VerifyBadgeAction(
              state: badge,
              verifiedLabel: detail == null
                  ? ''
                  : VerificationConstants.badgeLabel(detail.verificationBadge),
              onTap: () => onNavigate(RouteNames.verification),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton.icon(
                onPressed: () => onNavigate(RouteNames.editProfile),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  'Edit Profile',
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _BadgeState _badgeStateFor(UserModel? user) {
    if (user == null) return _BadgeState.unverified;
    final approved = user.verificationStatus == VerificationConstants.statusApproved;
    if (approved &&
        VerificationConstants.badgeLabel(user.verificationBadge).isNotEmpty) {
      return _BadgeState.verified;
    }
    switch (user.verificationStatus) {
      case VerificationConstants.statusPendingReview:
      case VerificationConstants.statusFlagged:
        return _BadgeState.pending;
      case VerificationConstants.statusRejected:
      case VerificationConstants.statusResubmissionRequested:
        return _BadgeState.resubmit;
      default:
        return _BadgeState.unverified;
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final bool verified;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.name,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final fallback = Center(
      child: Text(
        letter,
        style: AppFonts.plusJakarta(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: primary,
        ),
      ),
    );

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
              border: Border.all(color: primary.withValues(alpha: 0.18), width: 2),
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    ),
                  )
                : fallback,
          ),
          if (verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.verifiedBlue,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final hasValue = value != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.plusJakarta(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textTertiary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value ?? 'Not added',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    color: hasValue ? tokens.textPrimary : tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sheet's one prominent action: a filled "Verify Student Badge" button
/// when the user still has something to do, or a status tile once the badge
/// is earned or under review.
class _VerifyBadgeAction extends StatelessWidget {
  final _BadgeState state;
  final String verifiedLabel;
  final VoidCallback onTap;

  const _VerifyBadgeAction({
    required this.state,
    required this.verifiedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _BadgeState.unverified:
        return PrimaryButton(label: 'Verify Student Badge', onPressed: onTap);
      case _BadgeState.resubmit:
        return PrimaryButton(
          label: 'Resubmit Verification Documents',
          onPressed: onTap,
        );
      case _BadgeState.pending:
        return _StatusTile(
          icon: Icons.hourglass_top_rounded,
          color: AppTheme.warningColor,
          title: 'Verification in review',
          subtitle: 'Tap to view the status of your documents',
          onTap: onTap,
        );
      case _BadgeState.verified:
        return _StatusTile(
          icon: Icons.verified_rounded,
          color: AppTheme.verifiedBlue,
          title: verifiedLabel,
          subtitle: 'Your badge is active',
        );
    }
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(tokens.buttonRadius);

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.plusJakarta(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppFonts.plusJakarta(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.textTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
