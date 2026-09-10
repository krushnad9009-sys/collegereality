/// A PII-free, publicly readable copy of a student's post-consultation
/// review of a guide. Denormalized from `consultation_ratings` by the
/// `onConsultationRatingCreated` Cloud Function into
/// `guide_reviews/{consultationId}` so any authenticated user can render a
/// guide's review list without being able to read the private rating doc
/// — which carries `raterId`.
///
/// Deliberately carries NO reviewer identity: the public list shows
/// "Verified student", never a name or avatar.
class GuideReviewModel {
  final String consultationId;
  final String guideId;
  final int overall; // 1-5
  final String comment; // may be empty (star-only rating)
  final String collegeName; // the reviewer's college, for light context
  final DateTime createdAt;

  const GuideReviewModel({
    required this.consultationId,
    required this.guideId,
    required this.overall,
    required this.comment,
    required this.collegeName,
    required this.createdAt,
  });

  bool get hasComment => comment.trim().isNotEmpty;

  factory GuideReviewModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return GuideReviewModel(
      consultationId: docId ?? json['consultationId'] as String? ?? '',
      guideId: json['guideId'] as String? ?? '',
      overall: (json['overall'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'consultationId': consultationId,
        'guideId': guideId,
        'overall': overall,
        'comment': comment,
        'collegeName': collegeName,
        'createdAt': createdAt.toIso8601String(),
      };
}
