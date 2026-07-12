import '../../auth/models/user_model.dart';
import 'guide_stats_model.dart';

/// Public-facing guide profile — no phone, email, or real name.
class PublicGuideProfile {
  final String uid;
  final String anonymousAlias;
  final List<String> languagesKnown;
  final String? collegeName;
  final String? course;
  final int? batchYear;
  final bool isVerified;
  final GuideStatsModel stats;
  final GuideCommunicationSettings settings;

  const PublicGuideProfile({
    required this.uid,
    required this.anonymousAlias,
    required this.languagesKnown,
    this.collegeName,
    this.course,
    this.batchYear,
    this.isVerified = false,
    required this.stats,
    required this.settings,
  });

  factory PublicGuideProfile.fromUser(UserModel user) {
    return PublicGuideProfile(
      uid: user.uid,
      anonymousAlias: user.anonymousGuideAlias,
      languagesKnown: user.languagesKnown,
      collegeName: user.collegeName,
      course: user.course,
      batchYear: user.batchYear,
      isVerified: user.isVerified || user.isEmailVerified || user.isPhoneVerified,
      stats: user.guideStats,
      settings: user.communicationSettings,
    );
  }
}
