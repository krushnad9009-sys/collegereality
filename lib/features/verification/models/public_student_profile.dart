import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';

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

  bool get hasVerificationBadge => verificationBadge != VerificationConstants.badgeNone;

  factory PublicStudentProfile.fromUser(UserModel user) {
    return PublicStudentProfile(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Student',
      photoURL: user.photoURL,
      collegeName: user.collegeName,
      course: user.course,
      batchYear: user.batchYear,
      languagesKnown: user.languagesKnown,
      verificationBadge: user.verificationBadge,
    );
  }
}
