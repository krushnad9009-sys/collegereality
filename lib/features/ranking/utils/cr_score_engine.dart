import '../../../core/constants/cr_score_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/cr_score_model.dart';

/// Computes College Reality Score from verified review aggregates only.
class CrScoreEngine {
  CrScoreEngine._();

  static CrScoreSnapshot compute(CollegeModel college) {
    return computeFromRatings(
      ratings: college.aggregatedRatings,
      reviewCount: college.reviewCount,
      updatedAt: college.crScoreUpdatedAt,
    );
  }

  static CrScoreSnapshot computeFromRatings({
    required CollegeRatings ratings,
    required int reviewCount,
    DateTime? updatedAt,
  }) {
    if (reviewCount <= 0) {
      return CrScoreSnapshot(
        score: 0,
        verifiedReviewCount: 0,
        updatedAt: updatedAt,
      );
    }

    final categories = CrScoreCategories(
      education: _categoryScore([
        ratings.teaching,
        ratings.faculty,
        ratings.labs,
        ratings.attendance,
      ]),
      placements: _categoryScore([ratings.placements]),
      campusLife: _categoryScore([
        ratings.campusLife,
        ratings.sports,
        ratings.food,
        ratings.hostel,
      ]),
      infrastructure: _categoryScore([
        ratings.infrastructure,
        ratings.library,
      ]),
      safety: _categoryScore([
        ratings.safety,
        ratings.attendance,
      ]),
    );

    final score = _weightedScore(categories).clamp(0, 100);

    return CrScoreSnapshot(
      score: double.parse(score.toStringAsFixed(1)),
      categories: categories,
      verifiedReviewCount: reviewCount,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> firestorePayload(CrScoreSnapshot snapshot) {
    return {
      'crScore': snapshot.score,
      'crScoreCategories': snapshot.categories.toJson(),
      'crScoreUpdatedAt': (snapshot.updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  static double effectiveScore(CollegeModel college) {
    if (college.crScore > 0) return college.crScore;
    return compute(college).score;
  }

  static double _weightedScore(CrScoreCategories categories) {
    return categories.education * CrScoreConstants.weightEducation +
        categories.placements * CrScoreConstants.weightPlacements +
        categories.campusLife * CrScoreConstants.weightCampusLife +
        categories.infrastructure * CrScoreConstants.weightInfrastructure +
        categories.safety * CrScoreConstants.weightSafety;
  }

  static double _categoryScore(List<double> ratings) {
    final valid = ratings.where((value) => value > 0).toList();
    if (valid.isEmpty) return 0;
    final average = valid.reduce((a, b) => a + b) / valid.length;
    return (average / 5 * 100).clamp(0, 100);
  }
}
