import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/user_provider.dart';
import '../../engagement/providers/engagement_provider.dart';
import 'user_quick_profile_sheet.dart';

/// Notification bell + profile avatar shown at the right of the Home app bar.
/// The avatar opens the simplified quick-profile sheet.
///
/// [onDark] controls whether the chrome is styled for a dark or gradient
/// background (translucent white glass) or for a light surface (tokens-based
/// tint).
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
            onTap: () => showUserQuickProfileSheet(context),
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
