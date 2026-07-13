import '../../auth/models/user_model.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../models/ecosystem_models.dart';

/// Resolves effective platform role from user profile and linked accounts.
class RoleService {
  static String resolveRole({
    UserModel? user,
    CollegeAccountModel? collegeAccount,
  }) {
    if (user == null) return RoleConstants.guest;

    if (user.userType == RoleConstants.userTypeSuperAdmin) {
      return RoleConstants.superAdmin;
    }
    if (user.userType == RoleConstants.userTypeAdmin) {
      return RoleConstants.admin;
    }
    if (user.userType == RoleConstants.userTypeModerator) {
      return RoleConstants.moderator;
    }
    if (collegeAccount != null && collegeAccount.isVerified) {
      return RoleConstants.officialCollege;
    }
    if (user.verificationBadge == VerificationConstants.badgeVerifiedFaculty) {
      return RoleConstants.verifiedFaculty;
    }
    if (user.verificationBadge == VerificationConstants.badgeVerifiedAlumni) {
      return RoleConstants.verifiedAlumni;
    }
    if (user.verificationBadge == VerificationConstants.badgeVerifiedStudent) {
      return RoleConstants.verifiedStudent;
    }
    return RoleConstants.student;
  }

  static bool canModerate(String role) =>
      role == RoleConstants.admin ||
      role == RoleConstants.superAdmin ||
      role == RoleConstants.moderator;

  static bool isVerifiedUser(String role) =>
      role == RoleConstants.verifiedStudent ||
      role == RoleConstants.verifiedAlumni ||
      role == RoleConstants.verifiedFaculty ||
      role == RoleConstants.officialCollege ||
      canModerate(role);

  static bool isFaculty(String role) => role == RoleConstants.verifiedFaculty;

  static bool isOfficialCollege(String role) =>
      role == RoleConstants.officialCollege;

  static bool isAlumni(String role) => role == RoleConstants.verifiedAlumni;
}
