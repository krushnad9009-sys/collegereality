import '../constants/ranking_constants.dart';
import '../../features/colleges/models/college_model.dart';
import '../../features/ranking/models/ranking_models.dart';

/// In-memory cache for ranking lists and analytics snapshots.
class RankingSessionCache {
  RankingSessionCache._();

  static final Map<String, _CacheEntry<List<CollegeModel>>> _rankings = {};
  static _CacheEntry<CollegeAnalyticsSnapshot>? _analytics;
  static _CacheEntry<List<CollegeInsightItem>>? _insights;

  static List<CollegeModel>? getRankingList(String key) {
    return _rankings[key]?.valueIfFresh();
  }

  static void setRankingList(String key, List<CollegeModel> colleges) {
    _rankings[key] = _CacheEntry(List.unmodifiable(colleges));
  }

  static CollegeAnalyticsSnapshot? getAnalytics() => _analytics?.valueIfFresh();

  static void setAnalytics(CollegeAnalyticsSnapshot snapshot) {
    _analytics = _CacheEntry(snapshot);
  }

  static List<CollegeInsightItem>? getInsights() => _insights?.valueIfFresh();

  static void setInsights(List<CollegeInsightItem> items) {
    _insights = _CacheEntry(List.unmodifiable(items));
  }

  static void clearAll() {
    _rankings.clear();
    _analytics = null;
    _insights = null;
  }

  static String rankingKey({
    String? scope,
    String? state,
    String? city,
    String? course,
    String? type,
    String? category,
  }) {
    return '${scope ?? 'all'}_${state ?? ''}_${city ?? ''}_${course ?? ''}_${type ?? ''}_${category ?? ''}';
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime at;

  _CacheEntry(this.value) : at = DateTime.now();

  T? valueIfFresh() {
    if (DateTime.now().difference(at) > RankingConstants.rankingCacheTtl) {
      return null;
    }
    return value;
  }
}
