class GuideStatsModel {
  final double overallRating;
  final int totalChats;
  final int totalCalls;
  final int totalRatings;
  final double helpfulPercent;
  final double respectfulPercent;
  final double recommendPercent;
  final int avgResponseTimeMinutes;
  final DateTime? lastActiveAt;
  final String badgeTier;

  // Paid-consultation aggregates (separate from the free call/chat rating
  // fields above, which cover unpaid guide interactions). Computed the same
  // way — client recomputes from all consultation_ratings on write, see
  // ConsultationRatingCalculator.
  final double consultationRatingAvg;
  final int completedConsultations;
  final double communicationAvg;
  final double helpfulOrRespectfulAvg;
  final double knowledgeOrSeriousnessAvg;
  final double genuineOrAppropriateAvg;

  const GuideStatsModel({
    this.overallRating = 0,
    this.totalChats = 0,
    this.totalCalls = 0,
    this.totalRatings = 0,
    this.helpfulPercent = 0,
    this.respectfulPercent = 0,
    this.recommendPercent = 0,
    this.avgResponseTimeMinutes = 0,
    this.lastActiveAt,
    this.badgeTier = 'none',
    this.consultationRatingAvg = 0,
    this.completedConsultations = 0,
    this.communicationAvg = 0,
    this.helpfulOrRespectfulAvg = 0,
    this.knowledgeOrSeriousnessAvg = 0,
    this.genuineOrAppropriateAvg = 0,
  });

  factory GuideStatsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GuideStatsModel();
    return GuideStatsModel(
      overallRating: (json['overallRating'] as num?)?.toDouble() ?? 0,
      totalChats: (json['totalChats'] as num?)?.toInt() ?? 0,
      totalCalls: (json['totalCalls'] as num?)?.toInt() ?? 0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      helpfulPercent: (json['helpfulPercent'] as num?)?.toDouble() ?? 0,
      respectfulPercent: (json['respectfulPercent'] as num?)?.toDouble() ?? 0,
      recommendPercent: (json['recommendPercent'] as num?)?.toDouble() ?? 0,
      avgResponseTimeMinutes:
          (json['avgResponseTimeMinutes'] as num?)?.toInt() ?? 0,
      lastActiveAt: _parseDate(json['lastActiveAt']),
      badgeTier: json['badgeTier'] as String? ?? 'none',
      consultationRatingAvg:
          (json['consultationRatingAvg'] as num?)?.toDouble() ?? 0,
      completedConsultations:
          (json['completedConsultations'] as num?)?.toInt() ?? 0,
      communicationAvg: (json['communicationAvg'] as num?)?.toDouble() ?? 0,
      helpfulOrRespectfulAvg:
          (json['helpfulOrRespectfulAvg'] as num?)?.toDouble() ?? 0,
      knowledgeOrSeriousnessAvg:
          (json['knowledgeOrSeriousnessAvg'] as num?)?.toDouble() ?? 0,
      genuineOrAppropriateAvg:
          (json['genuineOrAppropriateAvg'] as num?)?.toDouble() ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'overallRating': overallRating,
        'totalChats': totalChats,
        'totalCalls': totalCalls,
        'totalRatings': totalRatings,
        'helpfulPercent': helpfulPercent,
        'respectfulPercent': respectfulPercent,
        'recommendPercent': recommendPercent,
        'avgResponseTimeMinutes': avgResponseTimeMinutes,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'badgeTier': badgeTier,
        'consultationRatingAvg': consultationRatingAvg,
        'completedConsultations': completedConsultations,
        'communicationAvg': communicationAvg,
        'helpfulOrRespectfulAvg': helpfulOrRespectfulAvg,
        'knowledgeOrSeriousnessAvg': knowledgeOrSeriousnessAvg,
        'genuineOrAppropriateAvg': genuineOrAppropriateAvg,
      };

  GuideStatsModel copyWith({
    double? overallRating,
    int? totalChats,
    int? totalCalls,
    int? totalRatings,
    double? helpfulPercent,
    double? respectfulPercent,
    double? recommendPercent,
    int? avgResponseTimeMinutes,
    DateTime? lastActiveAt,
    String? badgeTier,
    double? consultationRatingAvg,
    int? completedConsultations,
    double? communicationAvg,
    double? helpfulOrRespectfulAvg,
    double? knowledgeOrSeriousnessAvg,
    double? genuineOrAppropriateAvg,
  }) {
    return GuideStatsModel(
      overallRating: overallRating ?? this.overallRating,
      totalChats: totalChats ?? this.totalChats,
      totalCalls: totalCalls ?? this.totalCalls,
      totalRatings: totalRatings ?? this.totalRatings,
      helpfulPercent: helpfulPercent ?? this.helpfulPercent,
      respectfulPercent: respectfulPercent ?? this.respectfulPercent,
      recommendPercent: recommendPercent ?? this.recommendPercent,
      avgResponseTimeMinutes:
          avgResponseTimeMinutes ?? this.avgResponseTimeMinutes,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      badgeTier: badgeTier ?? this.badgeTier,
      consultationRatingAvg:
          consultationRatingAvg ?? this.consultationRatingAvg,
      completedConsultations:
          completedConsultations ?? this.completedConsultations,
      communicationAvg: communicationAvg ?? this.communicationAvg,
      helpfulOrRespectfulAvg:
          helpfulOrRespectfulAvg ?? this.helpfulOrRespectfulAvg,
      knowledgeOrSeriousnessAvg:
          knowledgeOrSeriousnessAvg ?? this.knowledgeOrSeriousnessAvg,
      genuineOrAppropriateAvg:
          genuineOrAppropriateAvg ?? this.genuineOrAppropriateAvg,
    );
  }
}

/// One priced call option a guide offers, e.g. "voice, 15 min, ₹99".
class GuideCallPriceOption {
  final String type; // ConsultationConstants.typeCall | typeVideo
  final int minutes;
  final int pricePaise;

  const GuideCallPriceOption({
    required this.type,
    required this.minutes,
    required this.pricePaise,
  });

  factory GuideCallPriceOption.fromJson(Map<String, dynamic> json) {
    return GuideCallPriceOption(
      type: json['type'] as String? ?? 'call',
      minutes: (json['minutes'] as num?)?.toInt() ?? 15,
      pricePaise: (json['pricePaise'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'minutes': minutes,
        'pricePaise': pricePaise,
      };
}

class GuideCommunicationSettings {
  final bool isGuideAvailable;
  final bool videoCallsEnabled;
  final bool cameraDefaultOn;
  final bool blurBackground;
  final bool allowPublicProfile;

  // Paid-consultation availability/pricing — independent ON/OFF toggles per
  // channel, plus prices in paise (never a floating rupee amount).
  final bool chatAvailable;
  final bool callAvailable;
  final int chatPricePaise;
  final int chatDurationMinutes;
  final List<GuideCallPriceOption> callPricing;
  final List<String> areasOfExpertise;

  const GuideCommunicationSettings({
    this.isGuideAvailable = false,
    this.videoCallsEnabled = true,
    this.cameraDefaultOn = true,
    this.blurBackground = true,
    this.allowPublicProfile = false,
    this.chatAvailable = false,
    this.callAvailable = false,
    this.chatPricePaise = 0,
    this.chatDurationMinutes = 15,
    this.callPricing = const [],
    this.areasOfExpertise = const [],
  });

  bool get hasAnyConsultationPricing =>
      (chatAvailable && chatPricePaise > 0) ||
      (callAvailable && callPricing.any((p) => p.pricePaise > 0));

  factory GuideCommunicationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GuideCommunicationSettings();
    return GuideCommunicationSettings(
      isGuideAvailable: json['isGuideAvailable'] as bool? ?? false,
      videoCallsEnabled: json['videoCallsEnabled'] as bool? ?? true,
      cameraDefaultOn: json['cameraDefaultOn'] as bool? ?? true,
      blurBackground: json['blurBackground'] as bool? ?? true,
      allowPublicProfile: json['allowPublicProfile'] as bool? ?? false,
      chatAvailable: json['chatAvailable'] as bool? ?? false,
      callAvailable: json['callAvailable'] as bool? ?? false,
      chatPricePaise: (json['chatPricePaise'] as num?)?.toInt() ?? 0,
      chatDurationMinutes:
          (json['chatDurationMinutes'] as num?)?.toInt() ?? 15,
      callPricing: (json['callPricing'] as List<dynamic>?)
              ?.map((e) => GuideCallPriceOption.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      areasOfExpertise: (json['areasOfExpertise'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'isGuideAvailable': isGuideAvailable,
        'videoCallsEnabled': videoCallsEnabled,
        'cameraDefaultOn': cameraDefaultOn,
        'blurBackground': blurBackground,
        'allowPublicProfile': allowPublicProfile,
        'chatAvailable': chatAvailable,
        'callAvailable': callAvailable,
        'chatPricePaise': chatPricePaise,
        'chatDurationMinutes': chatDurationMinutes,
        'callPricing': callPricing.map((p) => p.toJson()).toList(),
        'areasOfExpertise': areasOfExpertise,
      };

  GuideCommunicationSettings copyWith({
    bool? isGuideAvailable,
    bool? videoCallsEnabled,
    bool? cameraDefaultOn,
    bool? blurBackground,
    bool? allowPublicProfile,
    bool? chatAvailable,
    bool? callAvailable,
    int? chatPricePaise,
    int? chatDurationMinutes,
    List<GuideCallPriceOption>? callPricing,
    List<String>? areasOfExpertise,
  }) {
    return GuideCommunicationSettings(
      isGuideAvailable: isGuideAvailable ?? this.isGuideAvailable,
      videoCallsEnabled: videoCallsEnabled ?? this.videoCallsEnabled,
      cameraDefaultOn: cameraDefaultOn ?? this.cameraDefaultOn,
      blurBackground: blurBackground ?? this.blurBackground,
      allowPublicProfile: allowPublicProfile ?? this.allowPublicProfile,
      chatAvailable: chatAvailable ?? this.chatAvailable,
      callAvailable: callAvailable ?? this.callAvailable,
      chatPricePaise: chatPricePaise ?? this.chatPricePaise,
      chatDurationMinutes: chatDurationMinutes ?? this.chatDurationMinutes,
      callPricing: callPricing ?? this.callPricing,
      areasOfExpertise: areasOfExpertise ?? this.areasOfExpertise,
    );
  }
}
