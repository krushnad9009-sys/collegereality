import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../engagement/providers/engagement_provider.dart';

/// Compact profile + notification actions for the home header.
///
/// [onDark] controls whether the bell/avatar chrome is styled for a dark or
/// gradient background (translucent white glass) or for a light surface
/// (tokens-based tint) — the menu content/logic is identical either way.
class HomeHeaderActions extends ConsumerWidget {
  final User user;
  final bool onDark;

  const HomeHeaderActions({required this.user, this.onDark = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;
    final displayName = userDetail?.effectivePublicDisplayName ??
        user.displayName ??
        'Student';
    final firstLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';
    final primary = Theme.of(context).colorScheme.primary;

    final chipBg = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : primary.withValues(alpha: 0.1);
    final chipBorder = onDark
        ? Colors.white.withValues(alpha: 0.35)
        : primary.withValues(alpha: 0.16);
    final letterColor = onDark ? Colors.white : primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NotificationBell(userId: user.uid, onDark: onDark),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showProfileMenu(context, ref),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chipBg,
                border: Border.all(color: chipBorder),
              ),
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _avatarLetter(firstLetter, letterColor),
                      ),
                    )
                  : _avatarLetter(firstLetter, letterColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarLetter(String letter, Color color) {
    return Center(
      child: Text(
        letter,
        style: AppFonts.plusJakarta(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    final displayName =
        userDetail?.effectivePublicDisplayName ?? user.displayName ?? 'Student';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final tokens = context.tokens;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    displayName,
                    style: AppFonts.plusJakarta(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Your account',
                    style: AppFonts.plusJakarta(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: tokens.borderSubtle),
                const SizedBox(height: 4),
                PremiumListRow(
                  leadingIcon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.profile);
                  },
                ),
                PremiumListRow(
                  leadingIcon: Icons.search_rounded,
                  title: 'Search Colleges',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.collegeSearch);
                  },
                ),
                PremiumListRow(
                  leadingIcon: Icons.rate_review_outlined,
                  title: 'My Reviews',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.myReviews);
                  },
                ),
                PremiumListRow(
                  leadingIcon: Icons.bookmark_outline_rounded,
                  title: 'Bookmarks',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.favorites);
                  },
                ),
                PremiumListRow(
                  leadingIcon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.notifications);
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final isAdminAsync = ref.watch(isAdminProvider);
                    return isAdminAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (isAdmin) {
                        if (!isAdmin) return const SizedBox.shrink();
                        return PremiumListRow(
                          leadingIcon: Icons.admin_panel_settings_outlined,
                          title: 'Admin Panel',
                          onTap: () {
                            Navigator.pop(context);
                            context.go(RouteNames.admin);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: tokens.borderSubtle),
                const SizedBox(height: 8),
                PremiumListRow(
                  leadingIcon: Icons.logout_rounded,
                  iconColor: AppTheme.errorColor,
                  title: 'Sign Out',
                  titleColor: AppTheme.errorColor,
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showSignOutConfirmation(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    DialogHelper.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Yes, Sign Out',
      cancelText: 'Cancel',
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await ref.read(authProvider.notifier).signOut();
        if (context.mounted) {
          context.go(RouteNames.login);
        }
      }
    });
  }
}

class HomeHeaderWidget extends ConsumerWidget {
  final User user;

  const HomeHeaderWidget({required this.user, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeHeaderActions(user: user);
  }
}

class _NotificationBell extends ConsumerWidget {
  final String userId;
  final bool onDark;

  const _NotificationBell({required this.userId, this.onDark = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    return unreadAsync.when(
      loading: () => _bellButton(context, 0, showBadge: false),
      error: (_, _) => _bellButton(context, 0, showBadge: false),
      data: (count) => _bellButton(context, count, showBadge: count > 0),
    );
  }

  Widget _bellButton(BuildContext context, int count, {required bool showBadge}) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = onDark ? Colors.white.withValues(alpha: 0.16) : primary.withValues(alpha: 0.1);
    final border = onDark ? Colors.white.withValues(alpha: 0.22) : primary.withValues(alpha: 0.16);
    final iconColor = onDark ? Colors.white : primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RouteNames.notifications),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: iconColor,
                size: 21,
              ),
              if (showBadge)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
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
