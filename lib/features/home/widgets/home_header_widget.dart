import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../engagement/providers/engagement_provider.dart';

/// Compact profile + notification actions for the home hero.
class HomeHeaderActions extends ConsumerWidget {
  final User user;

  const HomeHeaderActions({required this.user, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;
    final displayName = userDetail?.effectivePublicDisplayName ??
        user.displayName ??
        'Student';
    final firstLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NotificationBell(userId: user.uid),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showProfileMenu(context, ref),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _avatarLetter(firstLetter),
                      ),
                    )
                  : _avatarLetter(firstLetter),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarLetter(String letter) {
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.profile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search_rounded),
                  title: const Text('Search Colleges'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.collegeSearch);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.rate_review_outlined),
                  title: const Text('My Reviews'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.myReviews);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_outline_rounded),
                  title: const Text('Bookmarks'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(RouteNames.favorites);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
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
                        return ListTile(
                          leading:
                              const Icon(Icons.admin_panel_settings_outlined),
                          title: const Text('Admin Panel'),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(RouteNames.admin);
                          },
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: AppTheme.errorColor),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
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

  const _NotificationBell({required this.userId});

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RouteNames.notifications),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
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
