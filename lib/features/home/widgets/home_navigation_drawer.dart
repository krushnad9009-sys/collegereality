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
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/sign_out.dart';
import '../../communication/widgets/guide_online_presence_mixin.dart';
import '../../communication/widgets/guide_online_toggle_card.dart';

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
            const _GuideAvailabilityDrawerTile(),
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
                      onTap: () => _push(context, RouteNames.myReviews),
                    ),
                    _DrawerItem(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Bookmarks',
                      onTap: () => _push(context, RouteNames.favorites),
                    ),
                    _DrawerItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () => _push(context, RouteNames.notifications),
                    ),
                    if (userDetail?.communicationSettings.isGuideAvailable ??
                        false)
                      _DrawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Earnings & Payouts',
                        onTap: () => _push(context, RouteNames.earnings),
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
  /// Used for peer/tab-like destinations (Search) and sign-in/admin, which
  /// follow the same `go()` convention used to reach them elsewhere in the
  /// app.
  static void _go(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(route);
  }

  /// Same as [_go], but pushes the destination onto the navigation stack
  /// instead of replacing it. Used for standalone detail screens (My
  /// Reviews, Bookmarks, Notifications, Earnings & Payouts) so Home stays
  /// underneath them on the stack -- without this, `go()` would replace
  /// Home outright and the destination's back arrow would have nothing to
  /// pop back to.
  static void _push(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(route);
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

/// "Guide Availability Status" -- right below the profile header card, only
/// rendered for an approved verified guide with guide mode on. Shares its
/// write path/optimistic UI with the Profile hub's GuideOnlineToggleCard
/// via GuideOnlinePresenceLogic, so both toggles stay in sync and can't
/// regress independently.
class _GuideAvailabilityDrawerTile extends ConsumerStatefulWidget {
  const _GuideAvailabilityDrawerTile();

  @override
  ConsumerState<_GuideAvailabilityDrawerTile> createState() =>
      _GuideAvailabilityDrawerTileState();
}

class _GuideAvailabilityDrawerTileState
    extends ConsumerState<_GuideAvailabilityDrawerTile>
    with GuideOnlinePresenceLogic<_GuideAvailabilityDrawerTile> {
  UserModel? _user;

  @override
  UserModel get presenceUser => _user!;

  @override
  Widget build(BuildContext context) {
    // Drawer.build() re-runs every time the drawer is opened, and
    // resolveOnline() below watches a live Firestore stream (not a
    // one-shot fetch), so this always reflects the exact current state --
    // never a snapshot from whenever the drawer was last opened.
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;
    if (userDetail == null || !GuideOnlineToggleCard.isEligible(userDetail)) {
      return const SizedBox.shrink();
    }
    _user = userDetail;
    final online = resolveOnline();
    final tokens = context.tokens;

    const onColor = Color(0xFF16A34A);
    final offColor = Colors.grey.shade500;
    final activeColor = online ? onColor : offColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: activeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Guide Availability Status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    online ? 'Online' : 'Offline',
                    style: AppFonts.plusJakarta(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: online,
              onChanged: busy ? null : setGuideOnline,
              activeThumbColor: onColor,
            ),
          ],
        ),
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
