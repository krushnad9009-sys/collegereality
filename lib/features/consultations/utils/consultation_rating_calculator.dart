import '../../communication/models/guide_stats_model.dart';

/// Recomputes a guide's consultation-rating aggregate from every
/// `consultation_ratings` doc where they were the ratee (raterRole ==
/// 'student'). Mirrors the existing recomputeGuideStats pattern in
/// guide_stats_calculator.dart — same trust model, extended for the
/// paid-consultation criteria set.
GuideStatsModel recomputeConsultationStats({
  required GuideStatsModel current,
  required List<Map<String, dynamic>> studentRatings,
}) {
  final total = studentRatings.length;
  if (total == 0) return current;

  double sumOf(String Function(Map<String, dynamic>) key) {
    var sum = 0.0;
    for (final r in studentRatings) {
      final criteria = r['criteria'] as Map<String, dynamic>? ?? const {};
      sum += (criteria[key(r)] as num?)?.toDouble() ?? 0;
    }
    return sum;
  }

  var overallSum = 0.0;
  for (final r in studentRatings) {
    overallSum += (r['overall'] as num?)?.toDouble() ?? 0;
  }

  double avg(double sum) => double.parse((sum / total).toStringAsFixed(2));

  return current.copyWith(
    consultationRatingAvg: avg(overallSum),
    completedConsultations: total,
    communicationAvg: avg(sumOf((_) => 'communication')),
    helpfulOrRespectfulAvg: avg(sumOf((_) => 'criterion2')),
    knowledgeOrSeriousnessAvg: avg(sumOf((_) => 'criterion3')),
    genuineOrAppropriateAvg: avg(sumOf((_) => 'criterion4')),
  );
}

/// Lightweight, non-persisted summary of ratings a student has received
/// from guides after consultations — computed on demand (low read volume:
/// only guides reviewing a student's trust signal before/around a
/// consultation), not denormalized like guide-facing stats.
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
