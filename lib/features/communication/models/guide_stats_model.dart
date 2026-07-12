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
    );
  }
}

class GuideCommunicationSettings {
  final bool isGuideAvailable;
  final bool videoCallsEnabled;
  final bool cameraDefaultOn;
  final bool blurBackground;

  const GuideCommunicationSettings({
    this.isGuideAvailable = false,
    this.videoCallsEnabled = true,
    this.cameraDefaultOn = true,
    this.blurBackground = true,
  });

  factory GuideCommunicationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GuideCommunicationSettings();
    return GuideCommunicationSettings(
      isGuideAvailable: json['isGuideAvailable'] as bool? ?? false,
      videoCallsEnabled: json['videoCallsEnabled'] as bool? ?? true,
      cameraDefaultOn: json['cameraDefaultOn'] as bool? ?? true,
      blurBackground: json['blurBackground'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'isGuideAvailable': isGuideAvailable,
        'videoCallsEnabled': videoCallsEnabled,
        'cameraDefaultOn': cameraDefaultOn,
        'blurBackground': blurBackground,
      };

  GuideCommunicationSettings copyWith({
    bool? isGuideAvailable,
    bool? videoCallsEnabled,
    bool? cameraDefaultOn,
    bool? blurBackground,
  }) {
    return GuideCommunicationSettings(
      isGuideAvailable: isGuideAvailable ?? this.isGuideAvailable,
      videoCallsEnabled: videoCallsEnabled ?? this.videoCallsEnabled,
      cameraDefaultOn: cameraDefaultOn ?? this.cameraDefaultOn,
      blurBackground: blurBackground ?? this.blurBackground,
    );
  }
}
