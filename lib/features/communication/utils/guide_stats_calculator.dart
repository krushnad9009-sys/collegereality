import '../../../core/constants/communication_constants.dart';
import '../models/guide_stats_model.dart';

String buildAnonymousGuideAlias(String uid) {
  final hash = uid.hashCode.abs() % 10000;
  return 'Guide #$hash';
}

String computeBadgeTier(GuideStatsModel stats) {
  if (stats.overallRating >= 4.5 && stats.totalCalls >= 50) {
    return CommunicationConstants.subscriptionGold;
  }
  if (stats.overallRating >= 4.0 && stats.totalCalls >= 20) {
    return CommunicationConstants.subscriptionSilver;
  }
  if (stats.overallRating >= 3.5 && stats.totalCalls >= 5) {
    return CommunicationConstants.subscriptionBronze;
  }
  return 'none';
}

GuideStatsModel recomputeGuideStats({
  required GuideStatsModel current,
  required List<Map<String, dynamic>> ratings,
  required bool incrementCall,
  required bool incrementChat,
  int? responseTimeMinutes,
}) {
  var totalRatings = ratings.length;
  var starSum = 0.0;
  var helpfulCount = 0;
  var respectfulCount = 0;
  var recommendCount = 0;

  for (final r in ratings) {
    starSum += (r['stars'] as num?)?.toDouble() ?? 0;
    if (r['helpful'] == true) helpfulCount++;
    if (r['respectful'] == true) respectfulCount++;
    if (r['wouldRecommend'] == true) recommendCount++;
  }

  final overall = totalRatings == 0 ? 0.0 : starSum / totalRatings;
  double pct(int count) =>
      totalRatings == 0 ? 0.0 : (count / totalRatings) * 100;

  final updated = current.copyWith(
    overallRating: double.parse(overall.toStringAsFixed(1)),
    totalRatings: totalRatings,
    totalCalls: incrementCall ? current.totalCalls + 1 : current.totalCalls,
    totalChats: incrementChat ? current.totalChats + 1 : current.totalChats,
    helpfulPercent: double.parse(pct(helpfulCount).toStringAsFixed(1)),
    respectfulPercent: double.parse(pct(respectfulCount).toStringAsFixed(1)),
    recommendPercent: double.parse(pct(recommendCount).toStringAsFixed(1)),
    avgResponseTimeMinutes: responseTimeMinutes ?? current.avgResponseTimeMinutes,
    lastActiveAt: DateTime.now(),
  );

  return updated.copyWith(badgeTier: computeBadgeTier(updated));
}
