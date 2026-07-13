import '../../colleges/models/college_model.dart';
import '../models/ranking_models.dart';
import 'college_ranking_utils.dart';

List<CollegeInsightItem> buildCollegeInsights(List<CollegeModel> colleges) {
  final active = colleges.where((c) => c.isActive).toList();
  if (active.isEmpty) return [];

  final insights = <CollegeInsightItem>[];

  final bestPlacement = _bestBy(
    active,
    (c) => c.placements.placementPercentage.toDouble() + c.aggregatedRatings.placements * 10,
  );
  if (bestPlacement != null) {
    insights.add(CollegeInsightItem(
      insightType: 'best_placement',
      title: 'Best Placement College',
      description:
          '${bestPlacement.placements.placementPercentage}% placement · ${bestPlacement.placements.averagePackageLpa.toStringAsFixed(1)} LPA avg',
      college: bestPlacement,
    ));
  }

  final bestTeaching = _bestBy(active, (c) => c.aggregatedRatings.teaching);
  if (bestTeaching != null) {
    insights.add(CollegeInsightItem(
      insightType: 'best_teaching',
      title: 'Best Teaching Quality',
      description:
          'Teaching rating ${bestTeaching.aggregatedRatings.teaching.toStringAsFixed(1)}/5',
      college: bestTeaching,
    ));
  }

  final bestInfra = _bestBy(active, (c) => c.aggregatedRatings.infrastructure);
  if (bestInfra != null) {
    insights.add(CollegeInsightItem(
      insightType: 'best_infrastructure',
      title: 'Best Infrastructure',
      description:
          'Infrastructure rating ${bestInfra.aggregatedRatings.infrastructure.toStringAsFixed(1)}/5',
      college: bestInfra,
    ));
  }

  final bestValue = _bestBy(active, computeRoiScore);
  if (bestValue != null) {
    insights.add(CollegeInsightItem(
      insightType: 'best_value',
      title: 'Best Value for Money',
      description: 'ROI score ${computeRoiScore(bestValue).toStringAsFixed(0)}/100 · ${formatFees(bestValue)}',
      college: bestValue,
    ));
  }

  final fastestGrowing = _bestBy(
    active,
    (c) => c.reviewCount.toDouble() + (c.isFeatured ? 20 : 0),
  );
  if (fastestGrowing != null) {
    insights.add(CollegeInsightItem(
      insightType: 'fastest_growing',
      title: 'Fastest Growing College',
      description: '${fastestGrowing.reviewCount} reviews and rising student interest',
      college: fastestGrowing,
    ));
  }

  final trending = _bestBy(
    active,
    (c) => computeOverallScore100(c) + (c.isFeatured ? 5 : 0) + c.reviewCount * 0.5,
  );
  if (trending != null) {
    insights.add(CollegeInsightItem(
      insightType: 'trending',
      title: 'Trending College',
      description: 'High engagement and strong overall score ${computeOverallScore100(trending).toStringAsFixed(0)}/100',
      college: trending,
    ));
  }

  return insights;
}

CollegeModel? _bestBy(List<CollegeModel> colleges, double Function(CollegeModel) scoreFn) {
  if (colleges.isEmpty) return null;
  colleges.sort((a, b) => scoreFn(b).compareTo(scoreFn(a)));
  return colleges.first;
}
