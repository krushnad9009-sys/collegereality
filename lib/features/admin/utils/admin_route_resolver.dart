import 'package:flutter/widgets.dart';

import '../../../config/router/route_names.dart';
import '../widgets/super_admin_scope.dart';

class AdminRouteResolver {
  AdminRouteResolver._();

  static String home(BuildContext context) {
    return SuperAdminScope.maybeOf(context)?.dashboardRoute ?? RouteNames.admin;
  }

  static String colleges(BuildContext context) {
    return SuperAdminScope.maybeOf(context)?.collegesRoute ?? RouteNames.adminColleges;
  }

  static String collegeNew(BuildContext context) {
    return SuperAdminScope.maybeOf(context)?.collegeNewRoute ?? RouteNames.adminCollegeNew;
  }

  static String collegeEdit(BuildContext context, String id) {
    final panel = SuperAdminScope.maybeOf(context);
    if (panel != null) return panel.collegeEditRoute(id);
    return RouteNames.adminCollegeEditPath(id);
  }
}
