class InteractionRatingModel {
  final String id;
  final String sessionId;
  final String raterId;
  final String rateeId;
  final int stars;
  final bool helpful;
  final bool respectful;
  final bool wouldRecommend;
  final String interactionType;
  final DateTime createdAt;

  const InteractionRatingModel({
    required this.id,
    required this.sessionId,
    required this.raterId,
    required this.rateeId,
    required this.stars,
    required this.helpful,
    required this.respectful,
    required this.wouldRecommend,
    required this.interactionType,
    required this.createdAt,
  });

  factory InteractionRatingModel.fromJson(Map<String, dynamic> json,
      {String? docId}) {
    return InteractionRatingModel(
      id: docId ?? json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      raterId: json['raterId'] as String? ?? '',
      rateeId: json['rateeId'] as String? ?? '',
      stars: (json['stars'] as num?)?.toInt() ?? 5,
      helpful: json['helpful'] as bool? ?? false,
      respectful: json['respectful'] as bool? ?? false,
      wouldRecommend: json['wouldRecommend'] as bool? ?? false,
      interactionType: json['interactionType'] as String? ?? 'call',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'raterId': raterId,
        'rateeId': rateeId,
        'stars': stars,
        'helpful': helpful,
        'respectful': respectful,
        'wouldRecommend': wouldRecommend,
        'interactionType': interactionType,
        'createdAt': createdAt.toIso8601String(),
      };

  InteractionRatingModel copyWith({String? id}) {
    return InteractionRatingModel(
      id: id ?? this.id,
      sessionId: sessionId,
      raterId: raterId,
      rateeId: rateeId,
      stars: stars,
      helpful: helpful,
      respectful: respectful,
      wouldRecommend: wouldRecommend,
      interactionType: interactionType,
      createdAt: createdAt,
    );
  }
}

class UserBlockModel {
  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  const UserBlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory UserBlockModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return UserBlockModel(
      id: docId ?? json['id'] as String? ?? '',
      blockerId: json['blockerId'] as String? ?? '',
      blockedId: json['blockedId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'blockerId': blockerId,
        'blockedId': blockedId,
        'createdAt': createdAt.toIso8601String(),
      };
}

class UserReportModel {
  final String id;
  final String reporterId;
  final String reportedId;
  final String? sessionId;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;

  const UserReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    this.sessionId,
    required this.reason,
    this.details = '',
    this.status = 'open',
    required this.createdAt,
  });

  factory UserReportModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return UserReportModel(
      id: docId ?? json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      reportedId: json['reportedId'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterId': reporterId,
        'reportedId': reportedId,
        'sessionId': sessionId,
        'reason': reason,
        'details': details,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
