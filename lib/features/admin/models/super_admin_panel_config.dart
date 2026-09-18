import '../widgets/admin_shell_layout.dart' show AdminNavItem;

// SuperAdminNavItem used to be its own class here, structurally identical
// to AdminNavItem (title/icon/route). AdminShellLayout's _Sidebar remapped
// every SuperAdminNavItem into a fresh AdminNavItem on every single build
// -- and since AdminShellLayout is a plain StatelessWidget re-wrapped
// around each admin screen, that "every build" is every navigation. Purely
// wasted allocations for identical data; now the panel config just uses
// AdminNavItem directly so there's nothing to remap.
typedef SuperAdminNavItem = AdminNavItem;

class SuperAdminPanelConfig {
  final String dashboardRoute;
  final String loginRoute;
  final String collegesRoute;
  final String collegeNewRoute;
  final String brandTitle;
  final String brandSubtitle;
  final List<AdminNavItem> navItems;

  const SuperAdminPanelConfig({
    required this.dashboardRoute,
    required this.loginRoute,
    required this.collegesRoute,
    required this.collegeNewRoute,
    required this.brandTitle,
    required this.brandSubtitle,
    required this.navItems,
  });

  String collegeEditRoute(String id) => '$collegesRoute/$id/edit';
}
