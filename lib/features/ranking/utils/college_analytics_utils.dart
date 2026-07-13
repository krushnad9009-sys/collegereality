import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/ranking_models.dart';
import 'college_ranking_utils.dart';

CollegeAnalyticsSnapshot buildAnalyticsSnapshot({
  required List<CollegeModel> colleges,
  Map<String, int> searchCounts = const {},
}) {
  final active = colleges.where((c) => c.isActive).toList();

  final popular = [...active]
    ..sort((a, b) {
      final scoreA = (a.isFeatured ? 100 : 0) + a.reviewCount + computeOverallScore100(a).round();
      final scoreB = (b.isFeatured ? 100 : 0) + b.reviewCount + computeOverallScore100(b).round();
      return scoreB.compareTo(scoreA);
    });

  final mostReviewed = [...active]..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

  final highestRated = [...active]
    ..sort((a, b) => b.aggregatedRatings.overall.compareTo(a.aggregatedRatings.overall));

  final mostSearched = [...active]
    ..sort((a, b) {
      final countA = searchCounts[a.id] ?? a.searchKeywords.length + a.reviewCount;
      final countB = searchCounts[b.id] ?? b.searchKeywords.length + b.reviewCount;
      return countB.compareTo(countA);
    });

  final limit = RankingConstants.analyticsTopLimit;

  return CollegeAnalyticsSnapshot(
    popularColleges: popular.take(limit).map((c) {
      return CollegeAnalyticsEntry(
        college: c,
        metricValue: (c.isFeatured ? 100 : 0) + c.reviewCount,
        metricLabel: 'Popularity score',
      );
    }).toList(),
    mostReviewed: mostReviewed.take(limit).map((c) {
      return CollegeAnalyticsEntry(
        college: c,
        metricValue: c.reviewCount,
        metricLabel: 'Reviews',
      );
    }).toList(),
    highestRated: highestRated.take(limit).map((c) {
      return CollegeAnalyticsEntry(
        college: c,
        metricValue: (c.aggregatedRatings.overall * 20).round(),
        metricLabel: '${c.aggregatedRatings.overall.toStringAsFixed(1)}/5',
      );
    }).toList(),
    mostSearched: mostSearched.take(limit).map((c) {
      final count = searchCounts[c.id] ?? c.searchKeywords.length;
      return CollegeAnalyticsEntry(
        college: c,
        metricValue: count,
        metricLabel: 'Search interest',
      );
    }).toList(),
  );
}
