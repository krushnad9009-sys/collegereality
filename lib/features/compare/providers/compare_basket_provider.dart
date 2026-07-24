import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cache/compare_session_cache.dart';
import '../../../core/constants/compare_constants.dart';
import '../../colleges/providers/college_provider.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../models/college_comparison_result.dart';
import '../models/saved_comparison_model.dart';
import '../services/college_comparison_service.dart';
import '../services/compare_saved_service.dart';
import '../services/compare_share_service.dart';

final collegeComparisonServiceProvider =
    Provider<CollegeComparisonService>((ref) => CollegeComparisonService());

final compareShareServiceProvider =
    Provider<CompareShareService>((ref) => CompareShareService());

final compareSavedServiceProvider = FutureProvider<CompareSavedService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CompareSavedService(prefs);
});

final savedComparisonsProvider =
    FutureProvider<List<SavedComparisonModel>>((ref) async {
  final service = await ref.watch(compareSavedServiceProvider.future);
  return service.readAll();
});

class CompareBasketState {
  final List<String> collegeIds;

  const CompareBasketState({this.collegeIds = const []});

  bool contains(String id) => collegeIds.contains(id);
  bool get isFull => collegeIds.length >= CompareConstants.maxColleges;
  bool get canCompare =>
      collegeIds.length >= CompareConstants.minCollegesToCompare;

  CompareBasketState copyWith({List<String>? collegeIds}) {
    return CompareBasketState(collegeIds: collegeIds ?? this.collegeIds);
  }
}

class CompareBasketNotifier extends StateNotifier<CompareBasketState> {
  CompareBasketNotifier() : super(const CompareBasketState());

  String? toggle(String collegeId) {
    if (state.contains(collegeId)) {
      state = state.copyWith(
        collegeIds: state.collegeIds.where((id) => id != collegeId).toList(),
      );
      return null;
    }
    if (state.isFull) {
      return 'You can compare up to ${CompareConstants.maxColleges} colleges.';
    }
    state = state.copyWith(
      collegeIds: [...state.collegeIds, collegeId],
    );
    return null;
  }

  void add(String collegeId) {
    if (state.contains(collegeId) || state.isFull) return;
    state = state.copyWith(collegeIds: [...state.collegeIds, collegeId]);
  }

  void remove(String collegeId) {
    if (!state.contains(collegeId)) return;
    state = state.copyWith(
      collegeIds: state.collegeIds.where((id) => id != collegeId).toList(),
    );
  }

  void clear() {
    state = const CompareBasketState();
  }

  void setColleges(List<String> ids) {
    state = CompareBasketState(
      collegeIds: ids.take(CompareConstants.maxColleges).toList(),
    );
  }
}

final compareBasketProvider =
    StateNotifierProvider<CompareBasketNotifier, CompareBasketState>((ref) {
  return CompareBasketNotifier();
});

final compareCollegesProvider =
    FutureProvider.family<CollegeComparisonResult?, List<String>>(
        (ref, collegeIds) async {
  if (collegeIds.length < CompareConstants.minCollegesToCompare) return null;

  final normalizedIds =
      collegeIds.take(CompareConstants.maxColleges).toList()..sort();
  final cached = CompareSessionCache.get(normalizedIds);
  if (cached != null) return cached;

  final repository = ref.watch(collegeRepositoryProvider);
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  final service = ref.watch(collegeComparisonServiceProvider);

  final colleges = await repository.getCollegesByIds(normalizedIds);
  if (colleges.length < CompareConstants.minCollegesToCompare) return null;

  final reviewsByCollege = <String, List<ReviewModel>>{};
  await Future.wait(
    colleges.map((college) async {
      final page = await reviewRepository.getReviewsPage(
        college.id,
        limit: CompareConstants.reviewSnippetLimit,
      );
      reviewsByCollege[college.id] = page.reviews;
    }),
  );

  final result = service.compare(
    colleges,
    reviewsByCollege: reviewsByCollege,
  );
  CompareSessionCache.set(normalizedIds, result);
  return result;
});
