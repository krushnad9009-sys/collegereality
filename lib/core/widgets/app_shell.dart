import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/route_names.dart';
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
    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showNav = _showBottomNav(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: showNav
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex(location),
                    onDestinationSelected: (index) => _onTap(context, index),
                    height: 68,
                    backgroundColor: isDark
                        ? AppTheme.gray800.withValues(alpha: 0.94)
                        : AppTheme.white.withValues(alpha: 0.94),
                    indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.14),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      _destination(Icons.home_rounded, 'Home'),
                      _destination(Icons.search_rounded, 'Search'),
                      _destination(Icons.auto_awesome_rounded, 'AI'),
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
