import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/ranking_models.dart';
import 'college_ranking_utils.dart';

List<SmartRecommendationResult> recommendColleges({
  required List<CollegeModel> colleges,
  required SmartRecommendationCriteria criteria,
  int limit = RankingConstants.smartRecommendationLimit,
}) {
  final tier = _examTier(criteria.examType, criteria.examScore);
  final results = <SmartRecommendationResult>[];

  for (final college in colleges) {
    if (!college.isActive) continue;
    var score = 0;
    final reasons = <String>[];

    if (criteria.preferredState != null &&
        criteria.preferredState!.isNotEmpty &&
        college.state.toLowerCase() == criteria.preferredState!.toLowerCase()) {
      score += 20;
      reasons.add('In preferred state ${college.state}');
    }
    if (criteria.preferredCity != null &&
        criteria.preferredCity!.isNotEmpty &&
        college.city.toLowerCase() == criteria.preferredCity!.toLowerCase()) {
      score += 15;
      reasons.add('In preferred city ${college.city}');
    }

    if (criteria.maxBudget != null && criteria.maxBudget! > 0) {
      final fee = _averageFee(college);
      if (fee > 0 && fee <= criteria.maxBudget!) {
        score += 25;
        reasons.add('Within budget (${formatFees(college)})');
      } else if (fee > criteria.maxBudget!) {
        continue;
      }
    }

    if (criteria.requireHostel) {
      if (college.hostel.available) {
        score += 15;
        reasons.add('Hostel available');
      } else {
        score -= 10;
      }
    }

    if (criteria.branchPreference != null && criteria.branchPreference!.isNotEmpty) {
      final branch = criteria.branchPreference!.toLowerCase();
      final hasBranch = college.courses.any((c) => c.toLowerCase().contains(branch)) ||
          college.displayCourses.any((c) => c.toLowerCase().contains(branch));
      if (hasBranch) {
        score += 20;
        reasons.add('Offers ${criteria.branchPreference}');
      }
    }

    if (criteria.preferPlacements) {
      score += (college.placements.placementPercentage * 0.3).round();
      score += (college.aggregatedRatings.placements * 5).round();
      if (college.placements.placementPercentage >= 80) {
        reasons.add('Strong placement record (${college.placements.placementPercentage}%)');
      }
    }

    score += (computeOverallScore100(college) * 0.3).round();
    score += _reservationBonus(criteria.reservationCategory);
    score += tier;

    if (college.type == 'government' && tier >= 15) {
      score += 10;
      reasons.add('Government college — good for your score tier');
    }

    if (score > 20) {
      results.add(SmartRecommendationResult(
        college: college,
        matchScore: score,
        reasons: reasons.take(4).toList(),
      ));
    }
  }

  results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
  return results.take(limit).toList();
}

int _examTier(String examType, int score) {
  if (score <= 0) return 5;
  switch (examType) {
    case RankingConstants.examJee:
      if (score <= 5000) return 30;
      if (score <= 20000) return 22;
      if (score <= 50000) return 15;
      if (score <= 100000) return 8;
      return 3;
    case RankingConstants.examNeet:
      if (score <= 5000) return 30;
      if (score <= 15000) return 22;
      if (score <= 40000) return 15;
      if (score <= 80000) return 8;
      return 3;
    case RankingConstants.examCet:
    default:
      if (score >= 95) return 30;
      if (score >= 85) return 22;
      if (score >= 70) return 15;
      if (score >= 55) return 8;
      return 3;
  }
}

int _reservationBonus(String category) {
  switch (category.toLowerCase()) {
    case 'sc':
    case 'st':
      return 8;
    case 'obc':
    case 'ews':
      return 5;
    default:
      return 0;
  }
}

int _averageFee(CollegeModel college) {
  final min = college.fees.tuitionMin;
  final max = college.fees.tuitionMax;
  if (min > 0 && max > 0) return ((min + max) / 2).round();
  if (max > 0) return max;
  return min;
}
