import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cache/ranking_session_cache.dart';
import '../models/ranking_models.dart';
import '../services/firestore_ranking_service.dart';
import '../utils/college_analytics_utils.dart';
import '../utils/college_insights_utils.dart';
import '../utils/college_ranking_utils.dart';
import '../utils/compare_recommendation_utils.dart';
import '../utils/smart_recommendation_engine.dart';

abstract class RankingRepository {
  Future<RankingPageResult> fetchRankedCollegesPage({
    String? state,
    String? city,
    String? course,
    String? collegeType,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit,
  });
  Future<List<CollegeRankEntry>> getRankedList({
    String category,
    String? state,
    String? city,
    String? course,
    String? collegeType,
    int limit,
  });
  Future<List<SmartRecommendationResult>> getSmartRecommendations(
    SmartRecommendationCriteria criteria,
  );
  Future<List<CompareRecommendationItem>> getCompareRecommendations({
    SmartRecommendationCriteria? criteria,
  });
  Future<List<CollegeInsightItem>> getInsights();
  Future<CollegeAnalyticsSnapshot> getAnalytics();
  Future<void> recordCollegeView(String collegeId, String userId);
}

class RankingRepositoryImpl implements RankingRepository {
  final FirestoreRankingService _service;

  RankingRepositoryImpl(this._service);

  @override
  Future<RankingPageResult> fetchRankedCollegesPage({
    String? state,
    String? city,
    String? course,
    String? collegeType,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 24,
  }) =>
      _service.fetchRankedCollegesPage(
        state: state,
        city: city,
        course: course,
        collegeType: collegeType,
        startAfter: startAfter,
        limit: limit,
      );

  @override
  Future<List<CollegeRankEntry>> getRankedList({
    String category = 'overall',
    String? state,
    String? city,
    String? course,
    String? collegeType,
    int limit = 50,
  }) async {
    final cacheKey = RankingSessionCache.rankingKey(
      scope: category,
      state: state,
      city: city,
      course: course,
      type: collegeType,
    );
    var colleges = RankingSessionCache.getRankingList(cacheKey);
    colleges ??= await _service.fetchFeaturedForRanking(limit: 100);
    if (colleges.isNotEmpty) {
      RankingSessionCache.setRankingList(cacheKey, colleges);
    }
    return rankColleges(
      colleges: colleges,
      category: category,
      state: state,
      city: city,
      course: course,
      collegeType: collegeType,
      limit: limit,
    );
  }

  @override
  Future<List<SmartRecommendationResult>> getSmartRecommendations(
    SmartRecommendationCriteria criteria,
  ) async {
    final colleges = await _service.fetchFeaturedForRanking(limit: 100);
    return recommendColleges(colleges: colleges, criteria: criteria);
  }

  @override
  Future<List<CompareRecommendationItem>> getCompareRecommendations({
    SmartRecommendationCriteria? criteria,
  }) async {
    final colleges = await _service.fetchFeaturedForRanking(limit: 100);
    return buildCompareRecommendations(colleges: colleges, criteria: criteria);
  }

  @override
  Future<List<CollegeInsightItem>> getInsights() async {
    final cached = RankingSessionCache.getInsights();
    if (cached != null) return cached;
    final colleges = await _service.fetchFeaturedForRanking(limit: 100);
    final insights = buildCollegeInsights(colleges);
    RankingSessionCache.setInsights(insights);
    return insights;
  }

  @override
  Future<CollegeAnalyticsSnapshot> getAnalytics() async {
    final cached = RankingSessionCache.getAnalytics();
    if (cached != null) return cached;
    final colleges = await _service.fetchFeaturedForRanking(limit: 100);
    final searchCounts = await _service.fetchSearchCounts();
    final snapshot = buildAnalyticsSnapshot(
      colleges: colleges,
      searchCounts: searchCounts,
    );
    RankingSessionCache.setAnalytics(snapshot);
    return snapshot;
  }

  @override
  Future<void> recordCollegeView(String collegeId, String userId) =>
      _service.recordCollegeEvent(
        collegeId: collegeId,
        eventType: 'view',
        userId: userId,
      );
}
