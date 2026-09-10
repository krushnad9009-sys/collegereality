// Both rating aggregates are now maintained server-side by the
// `onConsultationRatingCreated` Cloud Function
// (functions/src/consultationRatingLogic.js), serialised per rating so
// concurrent raters can't race the write, and (for the student side) so a
// guide never needs read access to another user's private rating docs.
// The client only READS the finished summaries.

/// PII-free summary of the ratings a student has received from guides,
/// read from `student_consultation_summaries/{studentId}` (written only by
/// the Cloud Function). No rater identity, no comments — averages + count.
class StudentConsultationSummary {
  final double overallAvg;
  final int totalRatings;
  final double communicationAvg;
  final double respectfulAvg;
  final double seriousnessAvg;
  final double appropriateAvg;

  const StudentConsultationSummary({
    this.overallAvg = 0,
    this.totalRatings = 0,
    this.communicationAvg = 0,
    this.respectfulAvg = 0,
    this.seriousnessAvg = 0,
    this.appropriateAvg = 0,
  });

  /// Reads the denormalized `student_consultation_summaries/{studentId}`
  /// document. Missing doc -> the zero summary.
  factory StudentConsultationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StudentConsultationSummary();
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return StudentConsultationSummary(
      overallAvg: d('overallAvg'),
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      communicationAvg: d('communicationAvg'),
      respectfulAvg: d('respectfulAvg'),
      seriousnessAvg: d('seriousnessAvg'),
      appropriateAvg: d('appropriateAvg'),
    );
  }

  factory StudentConsultationSummary.fromRatings(
    List<Map<String, dynamic>> guideRatings,
  ) {
    final total = guideRatings.length;
    if (total == 0) return const StudentConsultationSummary();

    double sum(String Function(Map<String, dynamic>) field) {
      var s = 0.0;
      for (final r in guideRatings) {
        final criteria = r['criteria'] as Map<String, dynamic>? ?? const {};
        s += (criteria[field(r)] as num?)?.toDouble() ?? 0;
      }
      return s;
    }

    var overallSum = 0.0;
    for (final r in guideRatings) {
      overallSum += (r['overall'] as num?)?.toDouble() ?? 0;
    }

    double avg(double s) => double.parse((s / total).toStringAsFixed(2));

    return StudentConsultationSummary(
      overallAvg: avg(overallSum),
      totalRatings: total,
      communicationAvg: avg(sum((_) => 'communication')),
      respectfulAvg: avg(sum((_) => 'criterion2')),
      seriousnessAvg: avg(sum((_) => 'criterion3')),
      appropriateAvg: avg(sum((_) => 'criterion4')),
    );
  }
}
