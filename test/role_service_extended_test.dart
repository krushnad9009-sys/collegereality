import 'package:college_reality_india/core/constants/role_constants.dart';
import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/ecosystem/services/role_service.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _u({String userType = 'student', String badge = VerificationConstants.badgeNone}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: 'u',
    email: 'a@b.com',
    userType: userType,
    verificationBadge: badge,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('guest when user is null', () {
    expect(RoleService.resolveRole(), RoleConstants.guest);
  });

  test('resolveRole maps admin and verified badges', () {
    expect(
      RoleService.resolveRole(user: _u(userType: RoleConstants.userTypeAdmin)),
      RoleConstants.admin,
    );
    expect(
      RoleService.resolveRole(
        user: _u(badge: VerificationConstants.badgeVerifiedStudent),
      ),
      RoleConstants.verifiedStudent,
    );
    expect(
      RoleService.resolveRole(
        user: _u(badge: VerificationConstants.badgeVerifiedAlumni),
      ),
      RoleConstants.verifiedAlumni,
    );
    expect(
      RoleService.resolveRole(
        user: _u(badge: VerificationConstants.badgeVerifiedFaculty),
      ),
      RoleConstants.verifiedFaculty,
    );
    expect(RoleService.resolveRole(user: _u()), RoleConstants.student);
  });

  test('moderation and verified helpers', () {
    expect(RoleService.canModerate(RoleConstants.admin), isTrue);
    expect(RoleService.canModerate(RoleConstants.student), isFalse);
    expect(RoleService.isVerifiedUser(RoleConstants.verifiedStudent), isTrue);
    expect(RoleService.isFaculty(RoleConstants.verifiedFaculty), isTrue);
    expect(RoleService.isAlumni(RoleConstants.verifiedAlumni), isTrue);
  });
}