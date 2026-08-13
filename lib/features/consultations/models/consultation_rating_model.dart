import '../../../core/constants/consultation_constants.dart';

/// Criteria labels differ by direction per the product spec, but are
/// stored under the same generic keys so one collection/model covers both
/// — see firestore.rules `isEligibleConsultationRating` and
/// ConsultationConstants.raterRole*.
///
/// Student -> guide:  communication, helpful,   knowledge,     genuine
/// Guide -> student:   communication, respectful, seriousness, appropriate
class ConsultationRatingModel {
  final String id; // `${consultationId}_${raterRole}`
  final String consultationId;
  final String raterId;
  final String raterRole; // ConsultationConstants.raterRole*
  final String rateeId;
  final int overall; // 1-5
  final int communication; // 1-5
  final int criterion2; // helpful | respectful
  final int criterion3; // knowledge | seriousness
  final int criterion4; // genuine | appropriate
  final DateTime createdAt;

  const ConsultationRatingModel({
    required this.id,
    required this.consultationId,
    required this.raterId,
    required this.raterRole,
    required this.rateeId,
    required this.overall,
    required this.communication,
    required this.criterion2,
    required this.criterion3,
    required this.criterion4,
    required this.createdAt,
  });

  static String docId(String consultationId, String raterRole) =>
      '${consultationId}_$raterRole';

  factory ConsultationRatingModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    final criteria = json['criteria'] as Map<String, dynamic>? ?? const {};
    return ConsultationRatingModel(
      id: docId ?? json['id'] as String? ?? '',
      consultationId: json['consultationId'] as String? ?? '',
      raterId: json['raterId'] as String? ?? '',
      raterRole: json['raterRole'] as String? ??
          ConsultationConstants.raterRoleStudent,
      rateeId: json['rateeId'] as String? ?? '',
      overall: (json['overall'] as num?)?.toInt() ?? 5,
      communication: (criteria['communication'] as num?)?.toInt() ?? 5,
      criterion2: (criteria['criterion2'] as num?)?.toInt() ?? 5,
      criterion3: (criteria['criterion3'] as num?)?.toInt() ?? 5,
      criterion4: (criteria['criterion4'] as num?)?.toInt() ?? 5,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'consultationId': consultationId,
        'raterId': raterId,
        'raterRole': raterRole,
        'rateeId': rateeId,
        'overall': overall,
        'criteria': {
          'communication': communication,
          'criterion2': criterion2,
          'criterion3': criterion3,
          'criterion4': criterion4,
        },
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Display labels for the two rater directions.
class ConsultationRatingLabels {
  final String criterion2;
  final String criterion3;
  final String criterion4;

  const ConsultationRatingLabels({
    required this.criterion2,
    required this.criterion3,
    required this.criterion4,
  });

  static const forStudentRatingGuide = ConsultationRatingLabels(
    criterion2: 'Helpful',
    criterion3: 'Knowledge',
    criterion4: 'Genuine / Trustworthy',
  );

  static const forGuideRatingStudent = ConsultationRatingLabels(
    criterion2: 'Respectful',
    criterion3: 'Serious about admission',
    criterion4: 'Appropriate behaviour',
  );

  static ConsultationRatingLabels forRole(String raterRole) =>
      raterRole == ConsultationConstants.raterRoleGuide
          ? forGuideRatingStudent
          : forStudentRatingGuide;
}
