import '../../auth/models/user_model.dart';
import '../../community/models/user_presence_model.dart';
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
  final String verificationStatus;
  final GuideStatsModel stats;
  final GuideCommunicationSettings settings;
  final UserPresenceModel presence;

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
    this.verificationStatus = 'incomplete',
    required this.stats,
    required this.settings,
    this.presence = const UserPresenceModel(),
  });

  bool get hasVerificationBadge =>
      verificationBadge != 'none' && verificationBadge.isNotEmpty;

  /// Only an approved verified_student/verified_alumni may be a paid guide
  /// — mirrors guideAvailabilityRequiresVerification() in firestore.rules.
  bool get isEligibleGuide =>
      (verificationBadge == 'verified_student' ||
          verificationBadge == 'verified_alumni') &&
      verificationStatus == 'approved';

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
      verificationStatus: user.verificationStatus,
      stats: user.guideStats,
      settings: user.communicationSettings,
      presence: user.presence,
    );
  }
}
