import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
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
  final Widget? floatingActionButton;

  const AdminShellLayout({
    required this.title,
    required this.child,
    this.showBack = true,
    this.isAdminUser = true,
    this.floatingActionButton,
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
    final isPanel = SuperAdminScope.maybeOf(context) != null;
    final tokens = context.tokens;

    if (isWide) {
      return Scaffold(
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            _Sidebar(currentPath: GoRouterState.of(context).uri.path, isAdminUser: isAdminUser),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(title: title, showBack: showBack, dashboardRoute: dashboardRoute, isPanel: isPanel),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        title: Text(
          title,
          style: isPanel
              ? GoogleFonts.inter(fontWeight: FontWeight.w600)
              : AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
        ),
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
  final bool isPanel;

  const _TopBar({
    required this.title,
    required this.showBack,
    required this.dashboardRoute,
    required this.isPanel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => context.go(dashboardRoute),
              ),
            Text(
              title,
              style: isPanel
                  ? GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: tokens.textPrimary)
                  : AppFonts.plusJakarta(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: tokens.textPrimary,
                    ),
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
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final sidebarColor = isPanel ? const Color(0xFF0F172A) : tokens.surfaceMuted;
    final selectedColor = isPanel ? Colors.white : primary;
    final textColor = isPanel ? const Color(0xFFCBD5E1) : null;

    return Container(
      width: 260,
      color: sidebarColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  panel?.brandTitle ?? 'College Reality',
                  style: isPanel
                      ? GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)
                      : AppFonts.plusJakarta(fontWeight: FontWeight.w800, fontSize: 16, color: primary),
                ),
                Text(
                  panel?.brandSubtitle ?? 'Admin Console',
                  style: isPanel
                      ? GoogleFonts.inter(fontSize: 12, color: textColor)
                      : AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            final selected = currentPath == item.route || currentPath.startsWith('${item.route}/');
            return ListTile(
              leading: Icon(
                item.icon,
                color: selected ? selectedColor : (isPanel ? textColor?.withValues(alpha: 0.7) : tokens.textSecondary),
              ),
              title: Text(
                item.title,
                style: isPanel
                    ? GoogleFonts.inter(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: selected ? Colors.white : textColor,
                      )
                    : AppFonts.plusJakarta(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: selected ? tokens.textPrimary : tokens.textSecondary,
                      ),
              ),
              selected: selected,
              selectedTileColor: isPanel ? primary.withValues(alpha: 0.2) : primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
              onTap: () {
                Navigator.of(context).maybePop();
                context.go(item.route);
              },
            );
          }),
          Divider(color: isPanel ? const Color(0xFF334155) : tokens.borderSubtle),
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
              leading: Icon(Icons.home_outlined, color: tokens.textSecondary),
              title: Text('Back to App', style: AppFonts.plusJakarta(fontSize: 14, color: tokens.textPrimary)),
              onTap: () => context.go(RouteNames.home),
            ),
        ],
      ),
    );
  }
}
