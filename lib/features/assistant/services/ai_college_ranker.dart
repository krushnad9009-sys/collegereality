import 'dart:math';

import '../../colleges/models/college_model.dart';
import '../models/ai_college_recommendation.dart';
import '../models/ai_query_intent.dart';

/// Deterministic ranker using only verified Firestore college fields.
class AiCollegeRanker {
  double score(CollegeModel college, AiQueryIntent intent) {
    final ratings = college.aggregatedRatings;
    final placements = college.placements;
    final acc = college.accreditation;

    var score = 0.0;

    switch (intent.sortBy) {
      case AiSortPriority.placements:
        score += placements.placementPercentage * 0.4;
        score += placements.averagePackageLpa * 8;
        score += ratings.placements * 12;
        score += (placements.highestPackageLpa * 0.5);
        break;
      case AiSortPriority.feesLow:
        final avgFee = _averageAnnualFee(college);
        score += max(0, 500000 - avgFee) / 5000;
        score += ratings.fees * 8;
        score += ratings.overall * 4;
        break;
      case AiSortPriority.hostel:
        score += college.hostel.available ? 25 : 0;
        score += ratings.hostel * 15;
        score += college.hostel.amenities.length * 0.5;
        break;
      case AiSortPriority.campusLife:
        score += ratings.campusLife * 18;
        score += ratings.sports * 4;
        score += ratings.food * 4;
        score += ratings.infrastructure * 4;
        break;
      case AiSortPriority.attendance:
        score += ratings.attendance * 20;
        score += ratings.overall * 4;
        break;
      case AiSortPriority.faculty:
        score += ratings.faculty * 18;
        score += ratings.teaching * 8;
        break;
      case AiSortPriority.naac:
        score += _naacScore(acc.naacGrade) * 20;
        score += ratings.overall * 6;
        break;
      case AiSortPriority.nirf:
        if (acc.nirfRank != null && acc.nirfRank! > 0) {
          score += max(0, 200 - acc.nirfRank!) * 0.5;
        }
        score += ratings.overall * 8;
        break;
      case AiSortPriority.overall:
        score += ratings.overall * 20;
        score += placements.placementPercentage * 0.15;
        score += placements.averagePackageLpa * 2;
        score += _naacScore(acc.naacGrade) * 5;
        if (acc.nirfRank != null && acc.nirfRank! > 0) {
          score += max(0, 150 - acc.nirfRank!) * 0.2;
        }
        break;
    }

    if (college.reviewCount > 0) {
      score += min(college.reviewCount, 50) * 0.15;
    }
    if (college.isFeatured) score += 3;

    if (intent.requireHostel && college.hostel.available) score += 5;
    if (intent.maxFees != null) {
      final fee = _averageAnnualFee(college);
      if (fee > 0 && fee <= intent.maxFees!) score += 8;
    }
    if (intent.naacGrade != null &&
        _normalizeGrade(acc.naacGrade) == _normalizeGrade(intent.naacGrade)) {
      score += 10;
    }

    return score;
  }

  List<AiCollegeRecommendation> rank(
    List<CollegeModel> colleges,
    AiQueryIntent intent, {
    int limit = 10,
  }) {
    final scored = colleges.map((c) {
      return MapEntry(c, score(c, intent));
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).toList().asMap().entries.map((entry) {
      final college = entry.value.key;
      final s = entry.value.value;
      return AiCollegeRecommendation(
        college: college,
        score: s,
        reasons: const [],
        rank: entry.key + 1,
      );
    }).toList();
  }

  static int _averageAnnualFee(CollegeModel college) {
    final min = college.fees.tuitionMin;
    final max = college.fees.tuitionMax;
    if (min > 0 && max > 0) return ((min + max) / 2).round();
    if (max > 0) return max;
    if (min > 0) return min;
    return 0;
  }

  static double _naacScore(String? grade) {
    switch (_normalizeGrade(grade)) {
      case 'A++':
        return 5;
      case 'A+':
        return 4.5;
      case 'A':
        return 4;
      case 'B++':
        return 3.5;
      case 'B+':
        return 3;
      case 'B':
        return 2.5;
      case 'C':
        return 2;
      default:
        return 0;
    }
  }

  static String _normalizeGrade(String? grade) {
    if (grade == null || grade.isEmpty) return '';
    return grade.replaceAll(' ', '').toUpperCase();
  }
}
