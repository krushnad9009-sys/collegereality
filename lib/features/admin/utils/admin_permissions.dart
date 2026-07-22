import '../../../core/constants/role_constants.dart';

/// Role-based admin UI permissions.
class AdminPermissions {
  AdminPermissions._();

  static bool isStaff(String? userType) =>
      RoleConstants.staffUserTypes.contains(userType);

  static bool isAdmin(String? userType) =>
      userType == RoleConstants.userTypeAdmin ||
      userType == RoleConstants.userTypeSuperAdmin;

  static bool isSuperAdmin(String? userType) =>
      userType == RoleConstants.userTypeSuperAdmin;

  static bool canManageColleges(String? userType) => isAdmin(userType);

  static bool canMergeColleges(String? userType) => isSuperAdmin(userType);

  static bool canBroadcast(String? userType) => isAdmin(userType);

  static bool canManageUsers(String? userType) => isAdmin(userType);

  static bool canModerateContent(String? userType) => isStaff(userType);

  static bool canManageVerification(String? userType) => isAdmin(userType);

  static bool canExportData(String? userType) => isAdmin(userType);

  static bool canViewAnalytics(String? userType) => isStaff(userType);
}
