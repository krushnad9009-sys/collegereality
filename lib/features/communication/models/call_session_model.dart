import '../../../core/constants/communication_constants.dart';

class CallSessionModel {
  final String id;
  final String callerId;
  final String calleeId;
  final String callType;
  final String status;
  final bool callerAccepted;
  final bool calleeAccepted;
  final String callerAlias;
  final String calleeAlias;
  final String callerTier;
  final String calleeTier;
  final int maxDurationSeconds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? endedBy;
  final bool isEmergencyEnd;
  final bool ratingsSubmittedCaller;
  final bool ratingsSubmittedCallee;

  const CallSessionModel({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.callType,
    required this.status,
    this.callerAccepted = false,
    this.calleeAccepted = false,
    required this.callerAlias,
    required this.calleeAlias,
    this.callerTier = CommunicationConstants.subscriptionFree,
    this.calleeTier = CommunicationConstants.subscriptionFree,
    required this.maxDurationSeconds,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.endedBy,
    this.isEmergencyEnd = false,
    this.ratingsSubmittedCaller = false,
    this.ratingsSubmittedCallee = false,
  });

  bool get isVideo => callType == CommunicationConstants.callTypeVideo;

  bool get bothAccepted => callerAccepted && calleeAccepted;

  bool isParticipant(String uid) => callerId == uid || calleeId == uid;

  String peerIdFor(String uid) => callerId == uid ? calleeId : callerId;

  String peerAliasFor(String uid) => callerId == uid ? calleeAlias : callerAlias;

  factory CallSessionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CallSessionModel(
      id: docId ?? json['id'] as String? ?? '',
      callerId: json['callerId'] as String? ?? '',
      calleeId: json['calleeId'] as String? ?? '',
      callType: json['callType'] as String? ?? CommunicationConstants.callTypeVoice,
      status: json['status'] as String? ?? CommunicationConstants.callStatusRequested,
      callerAccepted: json['callerAccepted'] as bool? ?? false,
      calleeAccepted: json['calleeAccepted'] as bool? ?? false,
      callerAlias: json['callerAlias'] as String? ?? 'Guide',
      calleeAlias: json['calleeAlias'] as String? ?? 'Guide',
      callerTier: json['callerTier'] as String? ?? CommunicationConstants.subscriptionFree,
      calleeTier: json['calleeTier'] as String? ?? CommunicationConstants.subscriptionFree,
      maxDurationSeconds: (json['maxDurationSeconds'] as num?)?.toInt() ?? 300,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? ''),
      endedBy: json['endedBy'] as String?,
      isEmergencyEnd: json['isEmergencyEnd'] as bool? ?? false,
      ratingsSubmittedCaller: json['ratingsSubmittedCaller'] as bool? ?? false,
      ratingsSubmittedCallee: json['ratingsSubmittedCallee'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'callerId': callerId,
        'calleeId': calleeId,
        'callType': callType,
        'status': status,
        'callerAccepted': callerAccepted,
        'calleeAccepted': calleeAccepted,
        'callerAlias': callerAlias,
        'calleeAlias': calleeAlias,
        'callerTier': callerTier,
        'calleeTier': calleeTier,
        'maxDurationSeconds': maxDurationSeconds,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'endedBy': endedBy,
        'isEmergencyEnd': isEmergencyEnd,
        'ratingsSubmittedCaller': ratingsSubmittedCaller,
        'ratingsSubmittedCallee': ratingsSubmittedCallee,
      };

  CallSessionModel copyWith({
    String? status,
    bool? callerAccepted,
    bool? calleeAccepted,
    DateTime? startedAt,
    DateTime? endedAt,
    String? endedBy,
    bool? isEmergencyEnd,
    bool? ratingsSubmittedCaller,
    bool? ratingsSubmittedCallee,
  }) {
    return CallSessionModel(
      id: id,
      callerId: callerId,
      calleeId: calleeId,
      callType: callType,
      status: status ?? this.status,
      callerAccepted: callerAccepted ?? this.callerAccepted,
      calleeAccepted: calleeAccepted ?? this.calleeAccepted,
      callerAlias: callerAlias,
      calleeAlias: calleeAlias,
      callerTier: callerTier,
      calleeTier: calleeTier,
      maxDurationSeconds: maxDurationSeconds,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      endedBy: endedBy ?? this.endedBy,
      isEmergencyEnd: isEmergencyEnd ?? this.isEmergencyEnd,
      ratingsSubmittedCaller:
          ratingsSubmittedCaller ?? this.ratingsSubmittedCaller,
      ratingsSubmittedCallee:
          ratingsSubmittedCallee ?? this.ratingsSubmittedCallee,
    );
  }
}
