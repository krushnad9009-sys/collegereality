import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/ranking_models.dart';
import 'college_ranking_utils.dart';
import 'smart_recommendation_engine.dart';

List<CompareRecommendationItem> buildCompareRecommendations({
  required List<CollegeModel> colleges,
  SmartRecommendationCriteria? criteria,
  int limit = RankingConstants.compareRecommendationLimit,
}) {
  final pool = criteria != null
      ? recommendColleges(colleges: colleges, criteria: criteria, limit: 20)
          .map((r) => r.college)
          .toList()
      : colleges.where((c) => c.isActive).toList();

  final ranked = rankColleges(colleges: pool, limit: limit * 2).take(limit).toList();

  return ranked.asMap().entries.map((entry) {
    final rankEntry = entry.value;
    final college = rankEntry.college;
    final strengths = _strengths(college);
    final weaknesses = _weaknesses(college);
    final roi = computeRoiScore(college);
    final why = _whyRecommended(college, rankEntry.overallScore, strengths);

    return CompareRecommendationItem(
      college: college,
      rank: entry.key + 1,
      overallScore: rankEntry.overallScore,
      roiScore: roi,
      whyRecommended: why,
      strengths: strengths,
      weaknesses: weaknesses,
      expectedPlacement: college.placements.averagePackageLpa > 0
          ? '${college.placements.averagePackageLpa.toStringAsFixed(1)} LPA avg · ${college.placements.placementPercentage}% placed'
          : 'Placement data limited',
      feesLabel: formatFees(college),
    );
  }).toList();
}

List<String> _strengths(CollegeModel college) {
  final s = <String>[];
  final r = college.aggregatedRatings;
  if (r.overall >= 4) s.add('High overall rating (${r.overall.toStringAsFixed(1)}/5)');
  if (college.placements.placementPercentage >= 80) {
    s.add('Excellent placement rate (${college.placements.placementPercentage}%)');
  }
  if (r.teaching >= 4) s.add('Strong teaching quality');
  if (r.infrastructure >= 4) s.add('Good infrastructure');
  if (college.hostel.available) s.add('Hostel facilities available');
  if (college.accreditation.naacGrade != null) {
    s.add('NAAC ${college.accreditation.naacGrade} accredited');
  }
  if (college.reviewCount >= 20) s.add('${college.reviewCount} verified reviews');
  return s.take(4).toList();
}

List<String> _weaknesses(CollegeModel college) {
  final w = <String>[];
  final r = college.aggregatedRatings;
  if (r.overall < 3.5 && r.overall > 0) w.add('Overall rating below average');
  if (college.placements.placementPercentage < 60 && college.placements.placementPercentage > 0) {
    w.add('Moderate placement rate');
  }
  if (!college.hostel.available) w.add('No on-campus hostel');
  if (college.fees.tuitionMax > 400000) w.add('Higher fee bracket');
  if (college.reviewCount < 5) w.add('Limited student reviews');
  return w.take(3).toList();
}

String _whyRecommended(CollegeModel college, double score, List<String> strengths) {
  if (strengths.isEmpty) {
    return 'Ranked ${score.toStringAsFixed(0)}/100 based on verified ratings and placement data.';
  }
  return 'Score ${score.toStringAsFixed(0)}/100 — ${strengths.first}.';
}
