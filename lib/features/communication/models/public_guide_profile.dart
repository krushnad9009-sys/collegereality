import '../../auth/models/user_model.dart';
import 'guide_stats_model.dart';

/// Public-facing guide profile — no phone, email, or documents.
class PublicGuideProfile {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String anonymousAlias;
  final List<String> languagesKnown;
  final String? collegeName;
  final String? course;
  final int? batchYear;
  final String verificationBadge;
  final GuideStatsModel stats;
  final GuideCommunicationSettings settings;

  const PublicGuideProfile({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.anonymousAlias,
    required this.languagesKnown,
    this.collegeName,
    this.course,
    this.batchYear,
    this.verificationBadge = 'none',
    required this.stats,
    required this.settings,
  });

  bool get hasVerificationBadge =>
      verificationBadge != 'none' && verificationBadge.isNotEmpty;

  factory PublicGuideProfile.fromUser(UserModel user) {
    return PublicGuideProfile(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.anonymousGuideAlias,
      photoURL: user.photoURL,
      anonymousAlias: user.anonymousGuideAlias,
      languagesKnown: user.languagesKnown,
      collegeName: user.collegeName,
      course: user.course,
      batchYear: user.batchYear,
      verificationBadge: user.verificationBadge,
      stats: user.guideStats,
      settings: user.communicationSettings,
    );
  }
}
