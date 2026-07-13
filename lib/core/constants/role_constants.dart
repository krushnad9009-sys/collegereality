/// Platform role definitions for RBAC.
class RoleConstants {
  RoleConstants._();

  static const String guest = 'guest';
  static const String student = 'student';
  static const String verifiedStudent = 'verified_student';
  static const String verifiedAlumni = 'verified_alumni';
  static const String verifiedFaculty = 'verified_faculty';
  static const String officialCollege = 'official_college';
  static const String moderator = 'moderator';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const String userTypeStudent = 'student';
  static const String userTypeModerator = 'moderator';
  static const String userTypeAdmin = 'admin';
  static const String userTypeSuperAdmin = 'super_admin';
  static const String userTypeCompany = 'company';

  static const List<String> staffUserTypes = [
    userTypeModerator,
    userTypeAdmin,
    userTypeSuperAdmin,
  ];

  static String label(String role) {
    switch (role) {
      case guest:
        return 'Guest';
      case verifiedStudent:
        return 'Verified Student';
      case verifiedAlumni:
        return 'Verified Alumni';
      case verifiedFaculty:
        return 'Verified Faculty';
      case officialCollege:
        return 'Official College';
      case moderator:
        return 'Moderator';
      case admin:
        return 'Admin';
      case superAdmin:
        return 'Super Admin';
      default:
        return 'Student';
    }
  }
}
