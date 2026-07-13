import 'dart:math';

import '../../colleges/models/college_model.dart';
import '../models/ranking_models.dart';

/// Computes normalized overall score (0–100) from verified college data.
double computeOverallScore100(CollegeModel college) {
  final ratings = college.aggregatedRatings;
  final placements = college.placements;

  var score = ratings.overall * 12;
  score += min(placements.placementPercentage * 0.2, 20);
  score += min(placements.averagePackageLpa * 2, 10);
  score += min(college.reviewCount * 0.2, 10);
  score += _naacBonus(college.accreditation.naacGrade);

  if (college.isFeatured) score += 2;
  return score.clamp(0, 100);
}

double categoryRatingScore(CollegeModel college, String category) {
  final ratings = college.aggregatedRatings;
  switch (category) {
    case 'placements':
      return ratings.placements * 15 +
          college.placements.placementPercentage * 0.15 +
          college.placements.averagePackageLpa;
    case 'teaching':
      return ratings.teaching * 18 + ratings.faculty * 6;
    case 'infrastructure':
      return ratings.infrastructure * 18 + ratings.labs * 4 + ratings.library * 4;
    case 'hostel':
      return ratings.hostel * 18 + (college.hostel.available ? 10 : 0);
    case 'fees':
      final fee = _averageAnnualFee(college);
      return ratings.fees * 12 + max(0, (400000 - fee) / 8000);
    case 'campusLife':
      return ratings.campusLife * 15 + ratings.sports * 4 + ratings.food * 4;
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

int _averageAnnualFee(CollegeModel college) {
  final min = college.fees.tuitionMin;
  final max = college.fees.tuitionMax;
  if (min > 0 && max > 0) return ((min + max) / 2).round();
  if (max > 0) return max;
  if (min > 0) return min;
  return 0;
}

double _naacBonus(String? grade) {
  if (grade == null || grade.isEmpty) return 0;
  final g = grade.replaceAll(' ', '').toUpperCase();
  switch (g) {
    case 'A++':
      return 8;
    case 'A+':
      return 6;
    case 'A':
      return 4;
    case 'B++':
    case 'B+':
      return 2;
    default:
      return 0;
  }
}

String formatScore(double score) => score.toStringAsFixed(1);

String formatFees(CollegeModel college) {
  final fee = _averageAnnualFee(college);
  if (fee <= 0) return 'Not available';
  if (fee >= 100000) return '₹${(fee / 100000).toStringAsFixed(1)}L/yr';
  return '₹${(fee / 1000).round()}K/yr';
}

double computeRoiScore(CollegeModel college) {
  final fee = _averageAnnualFee(college);
  if (fee <= 0 || college.placements.averagePackageLpa <= 0) return 0;
  final annualSalary = college.placements.averagePackageLpa * 100000;
  return ((annualSalary / fee) * 10).clamp(0, 100);
}
