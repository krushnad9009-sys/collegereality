import '../../auth/models/user_model.dart';

/// Public student profile for college connect — never exposes phone or email.
class PublicStudentProfile {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String? course;
  final String? branch;
  final int? batchYear;
  final String verificationBadge;
  final List<String> interests;

  const PublicStudentProfile({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.course,
    this.branch,
    this.batchYear,
    this.verificationBadge = 'none',
    this.interests = const [],
  });

  bool get hasVerificationBadge =>
      verificationBadge != 'none' && verificationBadge.isNotEmpty;

  factory PublicStudentProfile.fromUser(UserModel user) {
    if (!user.communicationSettings.allowPublicProfile) {
      throw StateError('Student has not enabled public profile.');
    }
    return PublicStudentProfile(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Student',
      photoURL: user.photoURL,
      course: user.course,
      branch: user.branch,
      batchYear: user.batchYear,
      verificationBadge: user.verificationBadge,
      interests: user.interests,
    );
  }
}
