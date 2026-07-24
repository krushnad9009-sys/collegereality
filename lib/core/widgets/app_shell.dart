import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/route_names.dart';
import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_theme.dart';

/// Premium bottom navigation shell for primary app destinations.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({required this.child, super.key});

  static const _tabRoutes = <String>[
    RouteNames.home,
    RouteNames.collegeSearch,
    RouteNames.assistant,
    RouteNames.community,
    RouteNames.profile,
  ];

  int _selectedIndex(String location) {
    if (location.startsWith(RouteNames.collegeSearch)) return 1;
    if (location.startsWith(RouteNames.assistant)) return 2;
    if (location.startsWith(RouteNames.community)) return 3;
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
    final tokens = context.tokens;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: showNav
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 16,
                0,
                isTablet ? 32 : 16,
                isTablet ? 16 : 12,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.navBarRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.navBarRadius),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex(location),
                    onDestinationSelected: (index) => _onTap(context, index),
                    height: isTablet ? 72 : 68,
                    backgroundColor: isDark
                        ? AppTheme.gray800.withValues(alpha: 0.95)
                        : AppTheme.white.withValues(alpha: 0.96),
                    indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.14),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    animationDuration: const Duration(milliseconds: 280),
                    destinations: [
                      _destination(Icons.home_rounded, 'Home'),
                      _destination(Icons.search_rounded, 'Search'),
                      _destination(Icons.auto_awesome_rounded, 'Assistant'),
                      _destination(Icons.forum_rounded, 'Community'),
                      _destination(Icons.person_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  NavigationDestination _destination(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon, size: 22),
      selectedIcon: Icon(icon, size: 24, color: AppTheme.primaryColor),
      label: label,
    );
  }
}
