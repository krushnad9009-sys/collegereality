import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/config/release_config.dart';
import '../../../core/widgets/index.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/sign_out.dart';

/// Left-side navigation drawer opened by the hamburger icon on Home.
///
/// Holds the app-level destinations that used to live in the avatar's
/// profile sheet. Signed-out visitors only get Search + Sign in; My Reviews,
/// Bookmarks and Notifications need an account, and Admin Panel additionally
/// needs an admin role.
class HomeNavigationDrawer extends ConsumerWidget {
  const HomeNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final user = ref.watch(currentUserProvider);
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    final signedInName = user == null
        ? null
        : userDetail?.effectivePublicDisplayName ?? user.displayName;

    return Drawer(
      backgroundColor: tokens.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(signedInName: signedInName),
            const _DrawerDivider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  _DrawerItem(
                    icon: Icons.search_rounded,
                    title: 'Search Colleges',
                    onTap: () => _go(context, RouteNames.collegeSearch),
                  ),
                  if (user != null) ...[
                    _DrawerItem(
                      icon: Icons.rate_review_outlined,
                      title: 'My Reviews',
                      onTap: () => _go(context, RouteNames.myReviews),
                    ),
                    _DrawerItem(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Bookmarks',
                      onTap: () => _go(context, RouteNames.favorites),
                    ),
                    _DrawerItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () => _go(context, RouteNames.notifications),
                    ),
                  ],
                  if (user != null && isAdmin) ...[
                    const _DrawerDivider(inset: true),
                    _DrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Panel',
                      onTap: () => _go(context, RouteNames.admin),
                    ),
                  ],
                ],
              ),
            ),
            const _DrawerDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: user != null
                  ? _DrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      color: AppTheme.errorColor,
                      onTap: () => _confirmSignOut(context, ref),
                    )
                  : _DrawerItem(
                      icon: Icons.login_rounded,
                      title: 'Sign in',
                      onTap: () => _go(context, RouteNames.login),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Closes the drawer, then navigates. The router is captured first because
  /// the drawer's own context is on its way out once it has been popped.
  static void _go(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(route);
  }

  /// The confirmation runs while the drawer is still open, so `context` and
  /// `ref` are both still mounted when [signOutAndRedirect] uses them --
  /// popping first would leave it holding a disposed `ref`.
  static Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Yes, Sign Out',
      cancelText: 'Cancel',
    );
    if (!confirmed || !context.mounted) return;
    await signOutAndRedirect(context, ref);
  }
}

class _DrawerHeader extends StatelessWidget {
  final String? signedInName;

  const _DrawerHeader({required this.signedInName});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.school_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReleaseConfig.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: tokens.textPrimary,
                  ),
                ),
                if (signedInName != null && signedInName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    signedInName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumListRow(
      leadingIcon: icon,
      iconColor: color,
      title: title,
      titleColor: color,
      showChevron: false,
      onTap: onTap,
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  final bool inset;

  const _DrawerDivider({this.inset = false});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: inset ? AppSpacing.md : 0,
      endIndent: inset ? AppSpacing.md : 0,
      color: context.tokens.borderSubtle,
    );
  }
}
