import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import 'super_admin_scope.dart';

class AdminNavItem {
  final String title;
  final IconData icon;
  final String route;
  final bool adminOnly;

  const AdminNavItem({
    required this.title,
    required this.icon,
    required this.route,
    this.adminOnly = false,
  });
}

const adminNavItems = [
  AdminNavItem(title: 'Dashboard', icon: Icons.dashboard_outlined, route: RouteNames.admin),
  AdminNavItem(title: 'Analytics', icon: Icons.analytics_outlined, route: RouteNames.adminAnalytics),
  AdminNavItem(title: 'Verification', icon: Icons.verified_user_outlined, route: RouteNames.adminVerification, adminOnly: true),
  AdminNavItem(title: 'Reviews', icon: Icons.rate_review_outlined, route: RouteNames.adminReviews),
  AdminNavItem(title: 'Community', icon: Icons.forum_outlined, route: RouteNames.adminCommunity),
  AdminNavItem(title: 'Colleges', icon: Icons.school_outlined, route: RouteNames.adminColleges, adminOnly: true),
  AdminNavItem(title: 'Merge Colleges', icon: Icons.merge_type, route: RouteNames.adminMergeColleges, adminOnly: true),
  AdminNavItem(title: 'Users', icon: Icons.people_outline, route: RouteNames.adminUsers, adminOnly: true),
  AdminNavItem(title: 'Broadcast', icon: Icons.campaign_outlined, route: RouteNames.adminAnnouncements, adminOnly: true),
  AdminNavItem(title: 'Reports', icon: Icons.flag_outlined, route: RouteNames.adminReports),
  AdminNavItem(title: 'Export', icon: Icons.download_outlined, route: RouteNames.adminExport, adminOnly: true),
  AdminNavItem(title: 'Q&A', icon: Icons.quiz_outlined, route: RouteNames.adminQuestions),
  AdminNavItem(title: 'Campus Life', icon: Icons.event_outlined, route: RouteNames.adminStudentLife),
];

class AdminShellLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final bool isAdminUser;

  const AdminShellLayout({
    required this.title,
    required this.child,
    this.showBack = true,
    this.isAdminUser = true,
    super.key,
  });

  String _dashboardRoute(BuildContext context) {
    return SuperAdminScope.maybeOf(context)?.dashboardRoute ?? RouteNames.admin;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 960;
    final dashboardRoute = _dashboardRoute(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(currentPath: GoRouterState.of(context).uri.path, isAdminUser: isAdminUser),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(title: title, showBack: showBack, dashboardRoute: dashboardRoute),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => context.go(dashboardRoute),
              )
            : null,
      ),
      drawer: Drawer(
        child: _Sidebar(currentPath: GoRouterState.of(context).uri.path, isAdminUser: isAdminUser),
      ),
      body: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final String dashboardRoute;

  const _TopBar({
    required this.title,
    required this.showBack,
    required this.dashboardRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => context.go(dashboardRoute),
              ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String currentPath;
  final bool isAdminUser;

  const _Sidebar({required this.currentPath, required this.isAdminUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = SuperAdminScope.maybeOf(context);
    final items = panel != null
        ? panel.navItems
            .map(
              (i) => AdminNavItem(title: i.title, icon: i.icon, route: i.route),
            )
            .toList()
        : adminNavItems.where((i) => !i.adminOnly || isAdminUser).toList();

    final isPanel = panel != null;
    final sidebarColor = isPanel ? const Color(0xFF0F172A) : (Theme.of(context).brightness == Brightness.dark ? AppTheme.gray900 : AppTheme.gray50);
    final selectedColor = isPanel ? Colors.white : AppTheme.primaryColor;
    final textColor = isPanel ? const Color(0xFFCBD5E1) : null;

    return Container(
      width: 260,
      color: sidebarColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  panel?.brandTitle ?? 'College Reality',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isPanel ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                Text(
                  panel?.brandSubtitle ?? 'Admin Console',
                  style: GoogleFonts.inter(fontSize: 12, color: isPanel ? textColor : null),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            final selected = currentPath == item.route || currentPath.startsWith('${item.route}/');
            return ListTile(
              leading: Icon(
                item.icon,
                color: selected ? selectedColor : (isPanel ? textColor?.withValues(alpha: 0.7) : null),
              ),
              title: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isPanel ? (selected ? Colors.white : textColor) : null,
                ),
              ),
              selected: selected,
              selectedTileColor: isPanel ? AppTheme.primaryColor.withValues(alpha: 0.2) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.of(context).maybePop();
                context.go(item.route);
              },
            );
          }),
          const Divider(color: Color(0xFF334155)),
          if (isPanel)
            ListTile(
              leading: Icon(Icons.logout, color: textColor),
              title: Text('Sign Out', style: GoogleFonts.inter(fontSize: 14, color: textColor)),
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go(panel.loginRoute);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text('Back to App', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () => context.go(RouteNames.home),
            ),
        ],
      ),
    );
  }
}
