import '../../../core/constants/consultation_constants.dart';

class ConsultationPriceInfo {
  final int grossPaise;
  final int platformFeePaise;
  final int guideAmountPaise;
  final String currency;

  const ConsultationPriceInfo({
    required this.grossPaise,
    this.platformFeePaise = 0,
    this.guideAmountPaise = 0,
    this.currency = ConsultationConstants.currencyInr,
  });

  factory ConsultationPriceInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ConsultationPriceInfo(grossPaise: 0);
    return ConsultationPriceInfo(
      grossPaise: (json['grossPaise'] as num?)?.toInt() ?? 0,
      platformFeePaise: (json['platformFeePaise'] as num?)?.toInt() ?? 0,
      guideAmountPaise: (json['guideAmountPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? ConsultationConstants.currencyInr,
    );
  }

  Map<String, dynamic> toJson() => {
        'grossPaise': grossPaise,
        'platformFeePaise': platformFeePaise,
        'guideAmountPaise': guideAmountPaise,
        'currency': currency,
      };

  String get grossDisplay => '₹${(grossPaise / 100).toStringAsFixed(0)}';
}

/// The source-of-truth record for one paid consultation. Status/money
/// transitions beyond the initial `requested` create are enforced by
/// firestore.rules + trusted Cloud Functions — see ConsultationService.
class ConsultationModel {
  final String id;
  final String studentId;
  final String guideId;
  final String? collegeId;
  final String type; // ConsultationConstants.type*
  final String status; // ConsultationConstants.status*
  final ConsultationPriceInfo priceInfo;
  final int durationMinutes;
  final String? callSessionId;
  final String? conversationId;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;
  final String? cancelReason;
  final String refundStatus;
  final bool ratingByStudentSubmitted;
  final bool ratingByGuideSubmitted;

  const ConsultationModel({
    required this.id,
    required this.studentId,
    required this.guideId,
    this.collegeId,
    required this.type,
    required this.status,
    required this.priceInfo,
    required this.durationMinutes,
    this.callSessionId,
    this.conversationId,
    this.paymentId,
    required this.createdAt,
    this.paidAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.expiresAt,
    this.cancelReason,
    this.refundStatus = ConsultationConstants.refundStatusNone,
    this.ratingByStudentSubmitted = false,
    this.ratingByGuideSubmitted = false,
  });

  bool isParticipant(String uid) => studentId == uid || guideId == uid;

  String peerIdFor(String uid) => uid == studentId ? guideId : studentId;

  bool get isPaid => status != ConsultationConstants.statusRequested &&
      status != ConsultationConstants.statusPaymentPending &&
      status != ConsultationConstants.statusCancelled &&
      status != ConsultationConstants.statusExpired;

  bool get isActive => status == ConsultationConstants.statusActive;

  bool get isCompleted => status == ConsultationConstants.statusCompleted;

  bool canRate(String uid) {
    if (!isCompleted) return false;
    if (uid == studentId) return !ratingByStudentSubmitted;
    if (uid == guideId) return !ratingByGuideSubmitted;
    return false;
  }

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory ConsultationModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ConsultationModel(
      id: docId ?? json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      guideId: json['guideId'] as String? ?? '',
      collegeId: json['collegeId'] as String?,
      type: json['type'] as String? ?? ConsultationConstants.typeChat,
      status: json['status'] as String? ?? ConsultationConstants.statusRequested,
      priceInfo: ConsultationPriceInfo.fromJson(
        json['priceInfo'] as Map<String, dynamic>?,
      ),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 15,
      callSessionId: json['callSessionId'] as String?,
      conversationId: json['conversationId'] as String?,
      paymentId: json['paymentId'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      paidAt: _parseDate(json['paidAt']),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      cancelledAt: _parseDate(json['cancelledAt']),
      expiresAt: _parseDate(json['expiresAt']),
      cancelReason: json['cancelReason'] as String?,
      refundStatus: json['refundStatus'] as String? ??
          ConsultationConstants.refundStatusNone,
      ratingByStudentSubmitted:
          json['ratingByStudentSubmitted'] as bool? ?? false,
      ratingByGuideSubmitted: json['ratingByGuideSubmitted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'guideId': guideId,
        'collegeId': collegeId,
        'type': type,
        'status': status,
        'priceInfo': priceInfo.toJson(),
        'durationMinutes': durationMinutes,
        'callSessionId': callSessionId,
        'conversationId': conversationId,
        'paymentId': paymentId,
        'createdAt': createdAt.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'cancelReason': cancelReason,
        'refundStatus': refundStatus,
        'ratingByStudentSubmitted': ratingByStudentSubmitted,
        'ratingByGuideSubmitted': ratingByGuideSubmitted,
      };
}
