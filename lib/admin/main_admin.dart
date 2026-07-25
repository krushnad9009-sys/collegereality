import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/firebase_bootstrap.dart';
import '../features/admin/models/super_admin_panel_config.dart';
import '../features/admin/widgets/super_admin_scope.dart';
import 'router/super_admin_route_names.dart';
import 'router/super_admin_router.dart';
import 'theme/super_admin_theme.dart';

const superAdminPanelConfig = SuperAdminPanelConfig(
  dashboardRoute: SuperAdminRouteNames.dashboard,
  loginRoute: SuperAdminRouteNames.login,
  collegesRoute: SuperAdminRouteNames.colleges,
  collegeNewRoute: SuperAdminRouteNames.collegeNew,
  brandTitle: 'College Reality',
  brandSubtitle: 'Super Admin Panel',
  navItems: [
    SuperAdminNavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: SuperAdminRouteNames.dashboard,
    ),
    SuperAdminNavItem(
      title: 'Users',
      icon: Icons.people_outline,
      route: SuperAdminRouteNames.users,
    ),
    SuperAdminNavItem(
      title: 'Colleges',
      icon: Icons.school_outlined,
      route: SuperAdminRouteNames.colleges,
    ),
    SuperAdminNavItem(
      title: 'Moderation',
      icon: Icons.shield_outlined,
      route: SuperAdminRouteNames.moderation,
    ),
    SuperAdminNavItem(
      title: 'Notifications',
      icon: Icons.campaign_outlined,
      route: SuperAdminRouteNames.notifications,
    ),
    SuperAdminNavItem(
      title: 'Analytics',
      icon: Icons.analytics_outlined,
      route: SuperAdminRouteNames.analytics,
    ),
    SuperAdminNavItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      route: SuperAdminRouteNames.settings,
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();

  runApp(
    const ProviderScope(
      child: SuperAdminScope(
        config: superAdminPanelConfig,
        child: SuperAdminWebApp(),
      ),
    ),
  );
}

class SuperAdminWebApp extends ConsumerWidget {
  const SuperAdminWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(superAdminRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'College Reality — Super Admin',
      theme: SuperAdminTheme.lightTheme,
      routerConfig: router,
    );
  }
}
