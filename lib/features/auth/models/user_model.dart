// Manual JSON serialization without code generation
import '../../../core/constants/verification_constants.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../communication/utils/guide_stats_calculator.dart';
import '../../community/models/user_presence_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String? phone;
  final String? displayName;
  final String? photoURL;
  final String userType;
  final bool isVerified;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String verificationBadge;
  final String verificationStatus;
  final String? collegeId;
  final String? collegeName;
  final String? course;
  final int? batchYear;
  final List<String> favoriteCollegeIds;
  final List<String> languagesKnown;
  final String subscriptionTier;
  final String anonymousGuideAlias;
  final GuideStatsModel guideStats;
  final GuideCommunicationSettings communicationSettings;
  final UserPresenceModel presence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.uid,
    required this.email,
    this.phone,
    this.displayName,
    this.photoURL,
    this.userType = 'student',
    this.isVerified = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.verificationBadge = VerificationConstants.badgeNone,
    this.verificationStatus = VerificationConstants.statusIncomplete,
    this.collegeId,
    this.collegeName,
    this.course,
    this.batchYear,
    this.favoriteCollegeIds = const [],
    this.languagesKnown = const [],
    this.subscriptionTier = 'free',
    String? anonymousGuideAlias,
    GuideStatsModel? guideStats,
    GuideCommunicationSettings? communicationSettings,
    UserPresenceModel? presence,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  })  : anonymousGuideAlias =
            anonymousGuideAlias ?? buildAnonymousGuideAlias(uid),
        guideStats = guideStats ?? const GuideStatsModel(),
        communicationSettings =
            communicationSettings ?? const GuideCommunicationSettings(),
        presence = presence ?? const UserPresenceModel();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String;
    return UserModel(
      uid: uid,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      userType: json['userType'] as String? ?? 'student',
      isVerified: json['isVerified'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      verificationBadge:
          json['verificationBadge'] as String? ?? VerificationConstants.badgeNone,
      verificationStatus: json['verificationStatus'] as String? ??
          VerificationConstants.statusIncomplete,
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
      course: json['course'] as String?,
      batchYear: (json['batchYear'] as num?)?.toInt(),
      favoriteCollegeIds: (json['favoriteCollegeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      languagesKnown: (json['languagesKnown'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
      anonymousGuideAlias: json['anonymousGuideAlias'] as String?,
      guideStats: GuideStatsModel.fromJson(
        json['guideStats'] as Map<String, dynamic>?,
      ),
      communicationSettings: GuideCommunicationSettings.fromJson(
        json['communicationSettings'] as Map<String, dynamic>?,
      ),
      presence: UserPresenceModel.fromJson(
        json['presence'] as Map<String, dynamic>?,
      ),
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt'] as DateTime
          : DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType,
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'verificationBadge': verificationBadge,
      'verificationStatus': verificationStatus,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'course': course,
      'batchYear': batchYear,
      'favoriteCollegeIds': favoriteCollegeIds,
      'languagesKnown': languagesKnown,
      'subscriptionTier': subscriptionTier,
      'anonymousGuideAlias': anonymousGuideAlias,
      'guideStats': guideStats.toJson(),
      'communicationSettings': communicationSettings.toJson(),
      'presence': presence.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phone,
    String? displayName,
    String? photoURL,
    String? userType,
    bool? isVerified,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? verificationBadge,
    String? verificationStatus,
    String? collegeId,
    String? collegeName,
    String? course,
    int? batchYear,
    List<String>? favoriteCollegeIds,
    List<String>? languagesKnown,
    String? subscriptionTier,
    String? anonymousGuideAlias,
    GuideStatsModel? guideStats,
    GuideCommunicationSettings? communicationSettings,
    UserPresenceModel? presence,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      course: course ?? this.course,
      batchYear: batchYear ?? this.batchYear,
      favoriteCollegeIds: favoriteCollegeIds ?? this.favoriteCollegeIds,
      languagesKnown: languagesKnown ?? this.languagesKnown,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      anonymousGuideAlias: anonymousGuideAlias ?? this.anonymousGuideAlias,
      guideStats: guideStats ?? this.guideStats,
      communicationSettings:
          communicationSettings ?? this.communicationSettings,
      presence: presence ?? this.presence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
