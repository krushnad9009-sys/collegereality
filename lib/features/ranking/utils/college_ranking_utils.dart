import '../../colleges/models/college_model.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../models/ranking_models.dart';
import 'cr_score_engine.dart';

/// Computes normalized CR Score (0–100) from verified review aggregates.
double computeOverallScore100(CollegeModel college) {
  return CrScoreEngine.effectiveScore(college);
}

double categoryRatingScore(CollegeModel college, String category) {
  final snapshot = CrScoreEngine.compute(college);
  switch (category) {
    case 'placements':
      return snapshot.categories.placements;
    case 'teaching':
    case 'education':
      return snapshot.categories.education;
    case 'infrastructure':
      return snapshot.categories.infrastructure;
    case 'hostel':
    case 'campusLife':
      return snapshot.categories.campusLife;
    case 'fees':
      return college.aggregatedRatings.fees * 20;
    case 'safety':
      return snapshot.categories.safety;
    default:
      return computeOverallScore100(college);
  }
}

List<CollegeRankEntry> rankColleges({
  required List<CollegeModel> colleges,
  String category = 'overall',
  String? state,
  String? city,
  String? course,
  String? collegeType,
  int limit = 50,
}) {
  var filtered = colleges.where((c) => c.isActive).toList();

  if (state != null && state.isNotEmpty) {
    filtered = filtered
        .where((c) => c.state.toLowerCase() == state.toLowerCase())
        .toList();
  }
  if (city != null && city.isNotEmpty) {
    filtered = filtered
        .where((c) => c.city.toLowerCase() == city.toLowerCase())
        .toList();
  }
  if (course != null && course.isNotEmpty) {
    filtered = filtered.where((c) {
      return c.courses.any((co) => co.toLowerCase().contains(course.toLowerCase())) ||
          c.displayCourses.any((co) => co.toLowerCase().contains(course.toLowerCase()));
    }).toList();
  }
  if (collegeType != null && collegeType.isNotEmpty) {
    filtered = filtered
        .where((c) => c.type.toLowerCase() == collegeType.toLowerCase())
        .toList();
  }

  final scored = filtered.map((c) {
    final overall = computeOverallScore100(c);
    final cat = category == 'overall' ? overall : categoryRatingScore(c, category);
    return MapEntry(c, (overall: overall, category: cat));
  }).toList()
    ..sort((a, b) => b.value.category.compareTo(a.value.category));

  return scored.take(limit).toList().asMap().entries.map((e) {
    final college = e.value.key;
    final scores = e.value.value;
    return CollegeRankEntry(
      college: college,
      overallScore: scores.overall,
      categoryScore: scores.category,
      rank: e.key + 1,
    );
  }).toList();
}

List<CollegeRankEntry> rankByState(List<CollegeModel> colleges, {String? state}) {
  return rankColleges(colleges: colleges, state: state);
}

List<CollegeRankEntry> rankByDistrict(List<CollegeModel> colleges, {String? city}) {
  return rankColleges(colleges: colleges, city: city);
}

List<CollegeRankEntry> rankByCourse(List<CollegeModel> colleges, {String? course}) {
  return rankColleges(colleges: colleges, course: course);
}

List<CollegeRankEntry> rankByType(List<CollegeModel> colleges, {String? collegeType}) {
  return rankColleges(colleges: colleges, collegeType: collegeType);
}

String formatScore(double score) => score.toStringAsFixed(1);

String formatFees(CollegeModel college) {
  final fee = _averageAnnualFee(college);
  if (fee <= 0) return 'Not available';
  return IndianCurrencyFormatter.format(fee.round());
}

int _averageAnnualFee(CollegeModel college) {
  final min = college.fees.tuitionMin;
  final max = college.fees.tuitionMax;
  if (min > 0 && max > 0) return ((min + max) / 2).round();
  if (max > 0) return max;
  if (min > 0) return min;
  return 0;
}

double computeRoiScore(CollegeModel college) {
  final fee = _averageAnnualFee(college);
  if (fee <= 0 || college.placements.averagePackageLpa <= 0) return 0;
  final annualSalary = college.placements.averagePackageLpa * 100000;
  return ((annualSalary / fee) * 10).clamp(0, 100);
}

String crScoreGrade(double score) => CrScoreConstants.gradeForScore(score);

String crScoreConfidence(int reviewCount) =>
    CrScoreConstants.confidenceLabel(reviewCount);
