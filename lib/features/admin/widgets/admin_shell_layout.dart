import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 960;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(currentPath: GoRouterState.of(context).uri.path, isAdminUser: isAdminUser),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(title: title, showBack: showBack),
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
                onPressed: () => context.go(RouteNames.admin),
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

  const _TopBar({required this.title, required this.showBack});

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
                onPressed: () => context.go(RouteNames.admin),
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

class _Sidebar extends StatelessWidget {
  final String currentPath;
  final bool isAdminUser;

  const _Sidebar({required this.currentPath, required this.isAdminUser});

  @override
  Widget build(BuildContext context) {
    final items = adminNavItems.where((i) => !i.adminOnly || isAdminUser).toList();

    return Container(
      width: 260,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.gray900
          : AppTheme.gray50,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'College Reality',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text('Admin Console', style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
          ),
          ...items.map((item) {
            final selected = currentPath == item.route;
            return ListTile(
              leading: Icon(item.icon, color: selected ? AppTheme.primaryColor : null),
              title: Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: selected,
              onTap: () {
                Navigator.of(context).maybePop();
                context.go(item.route);
              },
            );
          }),
          const Divider(),
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
