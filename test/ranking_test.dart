import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/ranking/models/ranking_models.dart';
import 'package:college_reality_india/features/ranking/utils/college_analytics_utils.dart';
import 'package:college_reality_india/features/ranking/utils/college_insights_utils.dart';
import 'package:college_reality_india/features/ranking/utils/college_ranking_utils.dart';
import 'package:college_reality_india/features/ranking/utils/compare_recommendation_utils.dart';
import 'package:college_reality_india/features/ranking/utils/smart_recommendation_engine.dart';

void main() {
  CollegeModel sample({
    required String id,
    required String name,
    required String city,
    required String state,
    double overall = 4.0,
    int placementPct = 80,
    int feeMax = 200000,
    String type = 'private',
    int reviewCount = 10,
    bool featured = false,
    bool hostel = true,
  }) {
    return CollegeModel(
      id: id,
      name: name,
      nameLower: name.toLowerCase(),
      slug: id,
      city: city,
      state: state,
      address: 'Test',
      type: type,
      courses: const ['B.Tech', 'Computer Engineering'],
      fees: CollegeFees(tuitionMin: feeMax ~/ 2, tuitionMax: feeMax, hostelAnnual: 50000),
      placements: CollegePlacements(
        highestPackageLpa: 20,
        averagePackageLpa: 8,
        placementPercentage: placementPct,
      ),
      hostel: CollegeHostel(available: hostel),
      aggregatedRatings: CollegeRatings(
        overall: overall,
        faculty: overall,
        infrastructure: overall,
        placements: overall,
        campusLife: overall,
        teaching: overall,
      ),
      reviewCount: reviewCount,
      isFeatured: featured,
    );
  }

  group('CollegeRankingUtils', () {
    test('computeOverallScore100 returns value between 0 and 100', () {
      final college = sample(id: '1', name: 'Test College', city: 'Pune', state: 'Maharashtra');
      final score = computeOverallScore100(college);
      expect(score, inInclusiveRange(0, 100));
    });

    test('rankColleges orders by placement category', () {
      final low = sample(
        id: '1',
        name: 'Low',
        city: 'Pune',
        state: 'Maharashtra',
        placementPct: 50,
        overall: 3,
      );
      final high = sample(
        id: '2',
        name: 'High',
        city: 'Pune',
        state: 'Maharashtra',
        placementPct: 95,
        overall: 4.5,
      );
      final ranked = rankColleges(
        colleges: [low, high],
        category: 'placements',
      );
      expect(ranked.first.college.id, '2');
    });

    test('rankColleges filters by state and type', () {
      final gov = sample(
        id: '1',
        name: 'Gov',
        city: 'Mumbai',
        state: 'Maharashtra',
        type: 'government',
      );
      final pvt = sample(
        id: '2',
        name: 'Pvt',
        city: 'Pune',
        state: 'Maharashtra',
        type: 'private',
      );
      final ranked = rankColleges(
        colleges: [gov, pvt],
        collegeType: 'government',
      );
      expect(ranked.length, 1);
      expect(ranked.first.college.type, 'government');
    });

    test('computeRoiScore increases with higher packages', () {
      final lowPkg = sample(
        id: '1',
        name: 'A',
        city: 'Pune',
        state: 'Maharashtra',
        placementPct: 70,
      );
      final highPkg = sample(
        id: '2',
        name: 'B',
        city: 'Pune',
        state: 'Maharashtra',
        placementPct: 70,
      );
      expect(computeRoiScore(highPkg), greaterThanOrEqualTo(computeRoiScore(lowPkg)));
    });
  });

  group('SmartRecommendationEngine', () {
    test('recommendColleges respects budget filter', () {
      final expensive = sample(
        id: '1',
        name: 'Expensive',
        city: 'Pune',
        state: 'Maharashtra',
        feeMax: 500000,
      );
      final affordable = sample(
        id: '2',
        name: 'Affordable',
        city: 'Pune',
        state: 'Maharashtra',
        feeMax: 150000,
      );
      const criteria = SmartRecommendationCriteria(maxBudget: 200000);
      final results = recommendColleges(
        colleges: [expensive, affordable],
        criteria: criteria,
      );
      expect(results.any((r) => r.college.id == '2'), isTrue);
      expect(results.any((r) => r.college.id == '1'), isFalse);
    });

    test('recommendColleges prefers preferred state', () {
      final mh = sample(id: '1', name: 'MH', city: 'Pune', state: 'Maharashtra');
      final ka = sample(id: '2', name: 'KA', city: 'Bangalore', state: 'Karnataka');
      const criteria = SmartRecommendationCriteria(preferredState: 'Maharashtra');
      final results = recommendColleges(colleges: [ka, mh], criteria: criteria);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.college.state, 'Maharashtra');
    });
  });

  group('CompareRecommendationUtils', () {
    test('buildCompareRecommendations returns up to 5 items', () {
      final colleges = List.generate(
        8,
        (i) => sample(
          id: '$i',
          name: 'College $i',
          city: 'Pune',
          state: 'Maharashtra',
          overall: 3 + i * 0.1,
        ),
      );
      final items = buildCompareRecommendations(colleges: colleges);
      expect(items.length, lessThanOrEqualTo(5));
      expect(items.first.strengths, isNotEmpty);
    });
  });

  group('CollegeInsightsUtils', () {
    test('buildCollegeInsights returns insight categories', () {
      final colleges = [
        sample(id: '1', name: 'A', city: 'Pune', state: 'MH', placementPct: 95, overall: 4.5),
        sample(id: '2', name: 'B', city: 'Pune', state: 'MH', placementPct: 60, overall: 3.5),
      ];
      final insights = buildCollegeInsights(colleges);
      expect(insights.any((i) => i.insightType == 'best_placement'), isTrue);
      expect(insights.any((i) => i.insightType == 'trending'), isTrue);
    });
  });

  group('CollegeAnalyticsUtils', () {
    test('buildAnalyticsSnapshot ranks by review count', () {
      final colleges = [
        sample(id: '1', name: 'A', city: 'Pune', state: 'MH', reviewCount: 5),
        sample(id: '2', name: 'B', city: 'Pune', state: 'MH', reviewCount: 50),
      ];
      final snapshot = buildAnalyticsSnapshot(colleges: colleges);
      expect(snapshot.mostReviewed.first.college.id, '2');
    });
  });
}
