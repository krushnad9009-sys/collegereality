import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';
import '../../profile/models/premium_student_profile.dart';

/// Public-facing student profile — never exposes phone, email, or documents.
class PublicStudentProfile {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String? collegeName;
  final String? course;
  final int? batchYear;
  final List<String> languagesKnown;
  final String verificationBadge;

  const PublicStudentProfile({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.collegeName,
    this.course,
    this.batchYear,
    this.languagesKnown = const [],
    this.verificationBadge = VerificationConstants.badgeNone,
  });

  bool get isVerifiedStudent =>
      verificationBadge == VerificationConstants.badgeVerifiedStudent;

  bool get isVerifiedAlumni =>
      verificationBadge == VerificationConstants.badgeVerifiedAlumni;

  bool get hasVerificationBadge =>
      verificationBadge != VerificationConstants.badgeNone;

  factory PublicStudentProfile.fromUser(UserModel user) {
    final premium = PremiumStudentProfile.fromUser(user);
    return PublicStudentProfile(
      uid: premium.uid,
      displayName: premium.displayName,
      photoURL: premium.photoURL,
      collegeName: premium.collegeName,
      course: premium.course,
      batchYear: premium.batchYear,
      languagesKnown: premium.languagesKnown,
      verificationBadge: premium.verificationBadge,
    );
  }
}
