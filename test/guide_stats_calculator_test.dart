import 'package:college_reality_india/core/constants/communication_constants.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:college_reality_india/features/communication/utils/guide_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildAnonymousGuideAlias is stable for uid', () {
    final a = buildAnonymousGuideAlias('user-1');
    final b = buildAnonymousGuideAlias('user-1');
    expect(a, b);
    expect(a, startsWith('Guide #'));
  });

  test('computeBadgeTier thresholds', () {
    expect(
      computeBadgeTier(const GuideStatsModel(overallRating: 4.6, totalCalls: 50)),
      CommunicationConstants.subscriptionGold,
    );
    expect(
      computeBadgeTier(const GuideStatsModel(overallRating: 4.1, totalCalls: 20)),
      CommunicationConstants.subscriptionSilver,
    );
    expect(
      computeBadgeTier(const GuideStatsModel(overallRating: 3.6, totalCalls: 5)),
      CommunicationConstants.subscriptionBronze,
    );
    expect(
      computeBadgeTier(const GuideStatsModel(overallRating: 3.0, totalCalls: 1)),
      'none',
    );
  });

  test('recomputeGuideStats aggregates ratings and increments', () {
    const current = GuideStatsModel(totalCalls: 2, totalChats: 1);
    final next = recomputeGuideStats(
      current: current,
      ratings: [
        {'stars': 5, 'helpful': true, 'respectful': true, 'wouldRecommend': true},
        {'stars': 3, 'helpful': false, 'respectful': true, 'wouldRecommend': false},
      ],
      incrementCall: true,
      incrementChat: true,
      responseTimeMinutes: 12,
    );
    expect(next.totalRatings, 2);
    expect(next.overallRating, 4.0);
    expect(next.totalCalls, 3);
    expect(next.totalChats, 2);
    expect(next.helpfulPercent, 50.0);
    expect(next.avgResponseTimeMinutes, 12);
    expect(next.badgeTier, isNotEmpty);
  });
}