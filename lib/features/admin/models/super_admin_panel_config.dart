import 'package:flutter/material.dart';

class SuperAdminNavItem {
  final String title;
  final IconData icon;
  final String route;

  const SuperAdminNavItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class SuperAdminPanelConfig {
  final String dashboardRoute;
  final String loginRoute;
  final String collegesRoute;
  final String collegeNewRoute;
  final String brandTitle;
  final String brandSubtitle;
  final List<SuperAdminNavItem> navItems;

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
