import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranking_models.dart';
import '../repositories/ranking_repository.dart';
import '../services/firestore_ranking_service.dart';

final firestoreRankingServiceProvider = Provider<FirestoreRankingService>((ref) {
  return FirestoreRankingService();
});

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepositoryImpl(ref.watch(firestoreRankingServiceProvider));
});

final collegeInsightsProvider = FutureProvider<List<CollegeInsightItem>>((ref) {
  return ref.watch(rankingRepositoryProvider).getInsights();
});

final collegeAnalyticsProvider = FutureProvider<CollegeAnalyticsSnapshot>((ref) {
  return ref.watch(rankingRepositoryProvider).getAnalytics();
});

final smartRecommendationsProvider =
    FutureProvider.family<List<SmartRecommendationResult>, SmartRecommendationCriteria>(
  (ref, criteria) {
    return ref.watch(rankingRepositoryProvider).getSmartRecommendations(criteria);
  },
);

final compareRecommendationsProvider =
    FutureProvider.family<List<CompareRecommendationItem>, SmartRecommendationCriteria?>(
  (ref, criteria) {
    return ref.watch(rankingRepositoryProvider).getCompareRecommendations(criteria: criteria);
  },
);

class RankingFilterState {
  final String category;
  final String? state;
  final String? city;
  final String? course;
  final String? collegeType;

  const RankingFilterState({
    this.category = 'overall',
    this.state,
    this.city,
    this.course,
    this.collegeType,
  });

  RankingFilterState copyWith({
    String? category,
    String? state,
    String? city,
    String? course,
    String? collegeType,
    bool clearState = false,
    bool clearCity = false,
    bool clearCourse = false,
    bool clearType = false,
  }) {
    return RankingFilterState(
      category: category ?? this.category,
      state: clearState ? null : (state ?? this.state),
      city: clearCity ? null : (city ?? this.city),
      course: clearCourse ? null : (course ?? this.course),
      collegeType: clearType ? null : (collegeType ?? this.collegeType),
    );
  }
}

class RankingFilterNotifier extends StateNotifier<RankingFilterState> {
  RankingFilterNotifier() : super(const RankingFilterState());

  void setCategory(String c) => state = state.copyWith(category: c);
  void setState(String? s) => state = state.copyWith(state: s, clearState: s == null);
  void setCity(String? c) => state = state.copyWith(city: c, clearCity: c == null);
  void setCourse(String? c) => state = state.copyWith(course: c, clearCourse: c == null);
  void setCollegeType(String? t) => state = state.copyWith(collegeType: t, clearType: t == null);
}

final rankingFilterProvider =
    StateNotifierProvider<RankingFilterNotifier, RankingFilterState>(
  (ref) => RankingFilterNotifier(),
);

final rankedCollegesProvider = FutureProvider<List<CollegeRankEntry>>((ref) {
  final filters = ref.watch(rankingFilterProvider);
  return ref.watch(rankingRepositoryProvider).getRankedList(
        category: filters.category,
        state: filters.state,
        city: filters.city,
        course: filters.course,
        collegeType: filters.collegeType,
      );
});
