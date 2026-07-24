import '../../../core/constants/cr_score_constants.dart';
import '../../colleges/models/college_model.dart';

class CrScoreCategories {
  final double education;
  final double placements;
  final double campusLife;
  final double infrastructure;
  final double safety;

  const CrScoreCategories({
    this.education = 0,
    this.placements = 0,
    this.campusLife = 0,
    this.infrastructure = 0,
    this.safety = 0,
  });

  double scoreFor(String key) {
    switch (key) {
      case CrScoreConstants.categoryEducation:
        return education;
      case CrScoreConstants.categoryPlacements:
        return placements;
      case CrScoreConstants.categoryCampusLife:
        return campusLife;
      case CrScoreConstants.categoryInfrastructure:
        return infrastructure;
      case CrScoreConstants.categorySafety:
        return safety;
      default:
        return 0;
    }
  }

  factory CrScoreCategories.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const CrScoreCategories();
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return CrScoreCategories(
      education: read(CrScoreConstants.categoryEducation),
      placements: read(CrScoreConstants.categoryPlacements),
      campusLife: read(CrScoreConstants.categoryCampusLife),
      infrastructure: read(CrScoreConstants.categoryInfrastructure),
      safety: read(CrScoreConstants.categorySafety),
    );
  }

  Map<String, dynamic> toJson() => {
        CrScoreConstants.categoryEducation: education,
        CrScoreConstants.categoryPlacements: placements,
        CrScoreConstants.categoryCampusLife: campusLife,
        CrScoreConstants.categoryInfrastructure: infrastructure,
        CrScoreConstants.categorySafety: safety,
      };
}

class CrScoreSnapshot {
  final double score;
  final CrScoreCategories categories;
  final int verifiedReviewCount;
  final DateTime? updatedAt;

  const CrScoreSnapshot({
    required this.score,
    this.categories = const CrScoreCategories(),
    this.verifiedReviewCount = 0,
    this.updatedAt,
  });

  String get grade => CrScoreConstants.gradeForScore(score);

  String get confidenceLabel =>
      CrScoreConstants.confidenceLabel(verifiedReviewCount);

  bool get hasEnoughData =>
      CrScoreConstants.hasEnoughData(verifiedReviewCount);

  factory CrScoreSnapshot.fromCollege(CollegeModel college) {
    return CrScoreSnapshot(
      score: college.crScore,
      categories: college.crScoreCategories,
      verifiedReviewCount: college.reviewCount,
      updatedAt: college.crScoreUpdatedAt,
    );
  }
}
