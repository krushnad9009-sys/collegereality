import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/route_names.dart';
import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/premium_home_theme.dart';
import '../../features/community/providers/presence_heartbeat_provider.dart';

/// Premium bottom navigation shell for primary app destinations. Also hosts
/// the app-lifecycle-aware presence heartbeat (see
/// PresenceHeartbeatController) for the entire authenticated app — a single
/// foreground timer here, not a write per screen.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  /// Optional side drawer for the current route. It lives on the shell's
  /// scaffold (not the page's) so it, and its scrim, cover the floating
  /// bottom navigation instead of sitting underneath it.
  final Widget? drawer;

  const AppShell({required this.child, this.drawer, super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Starts a >=heartbeatInterval foreground timer; auto-pauses/resumes
    // with app lifecycle and disposes with this shell (app session ends).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(presenceHeartbeatControllerProvider).start();
    });
  }

  Widget get child => widget.child;

  static const _tabRoutes = <String>[
    RouteNames.home,
    RouteNames.collegeSearch,
    RouteNames.assistant,
    RouteNames.communityPrivateChats,
    RouteNames.profile,
  ];

  int _selectedIndex(String location) {
    if (location.startsWith(RouteNames.collegeSearch)) return 1;
    if (location.startsWith(RouteNames.assistant)) return 2;
    if (location.startsWith(RouteNames.communityPrivateChats)) return 3;
    if (location.startsWith(RouteNames.profile)) return 4;
    return 0;
  }

  bool _showBottomNav(String location) =>
      _tabRoutes.any((route) => location == route);

  void _onTap(BuildContext context, int index) {
    if (index == _selectedIndex(GoRouterState.of(context).uri.path)) return;
    HapticFeedback.lightImpact();
    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showNav = _showBottomNav(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // On Home the active tab wears the hero's royal blue; on the other tabs
    // it keeps the brand teal.
    final isHome = location == RouteNames.home;
    final navTheme = isHome
        ? PremiumHomeTheme.resolve(Theme.of(context))
        : Theme.of(context);

    return Scaffold(
      body: child,
      drawer: widget.drawer,
      // Screens already reserve room for the bar through the bottom
      // MediaQuery padding; keeping the body extended preserves that.
      extendBody: true,
      bottomNavigationBar: showNav
          ? Theme(
              data: navTheme,
              child: Builder(
                builder: (navContext) {
                  final navTokens = navContext.tokens;
                  final accent = isHome
                      ? navTokens.heroColor
                      : AppTheme.primaryColor;
                  final surface = isDark ? AppTheme.gray800 : AppTheme.white;

                  // A minimal, docked bar: solid white, full width, one
                  // hairline on top. No blur, no floating pill, no shadow.
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppTheme.gray700
                              : navTokens.borderSubtle,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: _selectedIndex(location),
                      onDestinationSelected: (index) => _onTap(context, index),
                      height: 64,
                      backgroundColor: surface,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      indicatorColor: accent.withValues(alpha: 0.10),
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      animationDuration: const Duration(milliseconds: 280),
                      destinations: [
                        _destination(Icons.home_rounded, 'Home', accent),
                        _destination(Icons.search_rounded, 'Search', accent),
                        _destination(
                          Icons.auto_awesome_rounded,
                          'Assistant',
                          accent,
                        ),
                        _destination(
                          Icons.chat_bubble_rounded,
                          'Chats',
                          accent,
                          unselectedIcon: Icons.chat_bubble_outline_rounded,
                        ),
                        _destination(Icons.person_rounded, 'Profile', accent),
                      ],
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  NavigationDestination _destination(
    IconData icon,
    String label,
    Color accent, {
    IconData? unselectedIcon,
  }) {
    return NavigationDestination(
      icon: Icon(unselectedIcon ?? icon, size: 22),
      selectedIcon: Icon(icon, size: 24, color: accent),
      label: label,
    );
  }
}
