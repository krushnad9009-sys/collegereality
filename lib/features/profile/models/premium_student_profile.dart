import '../../../core/constants/profile_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';
import '../../community/models/user_presence_model.dart';
import 'student_trust_model.dart';

/// Premium public student profile — never exposes phone, email, or private docs.
class PremiumStudentProfile {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String? coverPhotoURL;
  final String? collegeName;
  final String? course;
  final String? branch;
  final int? batchYear;
  final List<String> languagesKnown;
  final String? aboutMe;
  final List<String> interests;
  final String verificationBadge;
  final StudentTrustModel trust;
  final UserPresenceModel presence;
  final String availabilityStatus;

  const PremiumStudentProfile({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.coverPhotoURL,
    this.collegeName,
    this.course,
    this.branch,
    this.batchYear,
    this.languagesKnown = const [],
    this.aboutMe,
    this.interests = const [],
    this.verificationBadge = VerificationConstants.badgeNone,
    required this.trust,
    required this.presence,
    this.availabilityStatus = ProfileConstants.availabilityOffline,
  });

  String get effectiveAvailability {
    if (availabilityStatus == ProfileConstants.availabilityOffline) {
      return ProfileConstants.availabilityOffline;
    }
    if (availabilityStatus == ProfileConstants.availabilityBusy) {
      return ProfileConstants.availabilityBusy;
    }
    if (presence.isOnline) {
      return ProfileConstants.availabilityAvailable;
    }
    return ProfileConstants.availabilityOffline;
  }

  factory PremiumStudentProfile.fromUser(UserModel user) {
    return PremiumStudentProfile(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Student',
      photoURL: user.photoURL,
      coverPhotoURL: user.coverPhotoURL,
      collegeName: user.collegeName,
      course: user.course,
      branch: user.branch,
      batchYear: user.batchYear,
      languagesKnown: user.languagesKnown,
      aboutMe: user.aboutMe,
      interests: user.interests,
      verificationBadge: user.verificationBadge,
      trust: StudentTrustModel.fromUser(user),
      presence: user.presence,
      availabilityStatus: user.presence.availabilityStatus,
    );
  }
}
