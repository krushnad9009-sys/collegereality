import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/config/release_config.dart';
import 'home_header_widget.dart';

/// Side gutter shared by the Home hero and the Home body, so the two can
/// never drift apart.
double homeContentGutter(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600
    ? AppSpacing.pageH
    : AppSpacing.pageHWide;

/// The top row of the Home hero, drawn on the royal-blue card:
///
///   [ ☰ ]  College Reality          [ 🔍 ] [ ⚙ ] [ 🔔 ] [ D ]
///
/// Hamburger (opens the navigation drawer), the app title, then Search,
/// Filter, Notification and Avatar. Signed-out visitors get a "Sign in" pill
/// in place of the bell + avatar. All icons are white on translucent-white
/// squares so they read crisply on the blue.
class HomeTopBar extends StatelessWidget {
  final User? user;
  final VoidCallback onMenuPressed;

  const HomeTopBar({
    required this.user,
    required this.onMenuPressed,
    super.key,
  });

  /// Edge length shared by every control in the row.
  static const double controlSize = 38;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BarButton(
          icon: Icons.menu_rounded,
          tooltip: 'Open navigation menu',
          onPressed: onMenuPressed,
        ),
        const SizedBox(width: 10),
        Expanded(
          // Scales down (rather than truncating) on very narrow phones, so
          // the title stays fully readable next to four controls.
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              ReleaseConfig.appName,
              maxLines: 1,
              style: AppFonts.plusJakarta(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _BarButton(
          icon: Icons.search_rounded,
          tooltip: 'Search colleges',
          onPressed: () => context.go(RouteNames.collegeSearch),
        ),
        const SizedBox(width: 6),
        _BarButton(
          icon: Icons.tune_rounded,
          tooltip: 'Filters',
          onPressed: () => context.go(RouteNames.collegeSearchFilters),
        ),
        const SizedBox(width: 6),
        if (user != null)
          HomeHeaderActions(user: user!, onDark: true, size: controlSize)
        else
          const _SignInPill(),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: HomeTopBar.controlSize,
            height: HomeTopBar.controlSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _SignInPill extends StatelessWidget {
  const _SignInPill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.go(RouteNames.login),
        child: Container(
          height: HomeTopBar.controlSize,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Sign in',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF093F72),
            ),
          ),
        ),
      ),
    );
  }
}
