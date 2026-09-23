import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../communication/widgets/guide_online_presence_mixin.dart';
import '../../communication/widgets/guide_online_toggle_card.dart';
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

  /// Edge length of the bell and avatar buttons.
  final double size;

  const HomeHeaderActions({
    required this.user,
    this.onDark = true,
    this.size = 42,
    super.key,
  });

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
        _NotificationBell(userId: user.uid, onDark: onDark, size: size),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showUserQuickProfileSheet(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: size,
              height: size,
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
  final double size;

  const _NotificationBell({
    required this.userId,
    this.onDark = true,
    this.size = 42,
  });

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
        // push, not go: Home must stay on the stack so Notifications' own
        // back arrow can pop straight back to it (see home_navigation_drawer
        // for the same fix on the drawer's Notifications item).
        onTap: () => context.push(RouteNames.notifications),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
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

/// Compact "You are Online/Offline" status bar for the very top of Home,
/// directly under the hamburger menu bar. Only rendered for an approved
/// verified guide who has guide mode on (same eligibility as
/// GuideOnlineToggleCard, the fuller version of this same toggle on the
/// Profile hub -- both share their write/optimistic-UI logic via
/// GuideOnlinePresenceLogic so there's exactly one place that can get the
/// Firestore sync wrong).
class GuideOnlineStatusBar extends ConsumerStatefulWidget {
  const GuideOnlineStatusBar({super.key});

  @override
  ConsumerState<GuideOnlineStatusBar> createState() =>
      _GuideOnlineStatusBarState();
}

class _GuideOnlineStatusBarState extends ConsumerState<GuideOnlineStatusBar>
    with GuideOnlinePresenceLogic<GuideOnlineStatusBar> {
  UserModel? _user;

  @override
  UserModel get presenceUser => _user!;

  @override
  Widget build(BuildContext context) {
    final userDetail = ref.watch(currentUserDetailProvider).valueOrNull;
    if (userDetail == null || !GuideOnlineToggleCard.isEligible(userDetail)) {
      return const SizedBox.shrink();
    }
    _user = userDetail;
    final online = resolveOnline();

    const onColor = Color(0xFF16A34A);
    final offColor = Colors.grey.shade500;
    final activeColor = online ? onColor : offColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              child: Text(
                online ? 'You are Online' : 'You are Offline',
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
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
