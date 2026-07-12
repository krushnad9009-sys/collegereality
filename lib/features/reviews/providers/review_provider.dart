import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';
import '../services/firestore_review_service.dart';

final firestoreReviewServiceProvider = Provider<FirestoreReviewService>((ref) {
  return FirestoreReviewService();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(firestoreReviewServiceProvider));
});

/// Holds freshly submitted reviews until the Firestore stream catches up.
class OptimisticReviewsNotifier
    extends StateNotifier<Map<String, List<ReviewModel>>> {
  OptimisticReviewsNotifier() : super(const {});

  void addReview(String collegeId, ReviewModel review) {
    final key = collegeId.trim();
    final existing = state[key] ?? [];
    final withoutDup = existing.where((r) => r.id != review.id).toList();
    state = {
      ...state,
      key: [review, ...withoutDup],
    };
  }

  void removeReview(String collegeId, String reviewId) {
    final key = collegeId.trim();
    final existing = state[key];
    if (existing == null) return;
    state = {
      ...state,
      key: existing.where((r) => r.id != reviewId).toList(),
    };
  }

  void clearCollege(String collegeId) {
    final key = collegeId.trim();
    if (!state.containsKey(key)) return;
    final next = Map<String, List<ReviewModel>>.from(state);
    next.remove(key);
    state = next;
  }
}

final optimisticReviewsProvider =
    StateNotifierProvider<OptimisticReviewsNotifier, Map<String, List<ReviewModel>>>(
  (ref) => OptimisticReviewsNotifier(),
);

List<ReviewModel> mergeReviews({
  required List<ReviewModel> streamReviews,
  required List<ReviewModel> optimistic,
}) {
  final byId = <String, ReviewModel>{};
  for (final review in optimistic) {
    byId[review.id] = review;
  }
  for (final review in streamReviews) {
    byId[review.id] = review;
  }
  final merged = byId.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
}

final collegeReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, collegeId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.watchReviewsByCollege(collegeId);
});

final mergedCollegeReviewsProvider =
    Provider.family<AsyncValue<List<ReviewModel>>, String>((ref, collegeId) {
  final streamAsync = ref.watch(collegeReviewsProvider(collegeId));
  final optimistic = ref.watch(optimisticReviewsProvider)[collegeId.trim()] ?? [];

  return streamAsync.whenData((streamReviews) {
    if (optimistic.isEmpty) return streamReviews;
    return mergeReviews(streamReviews: streamReviews, optimistic: optimistic);
  });
});

final userReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsByUser(user.uid);
});

final userCollegeReviewProvider =
    FutureProvider.family<ReviewModel?, UserCollegeReviewParams>(
        (ref, params) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUserReviewForCollege(params.userId, params.collegeId);
});

class UserCollegeReviewParams {
  final String userId;
  final String collegeId;

  const UserCollegeReviewParams({
    required this.userId,
    required this.collegeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCollegeReviewParams &&
          userId == other.userId &&
          collegeId == other.collegeId;

  @override
  int get hashCode => Object.hash(userId, collegeId);
}

final allReviewsAdminProvider =
    FutureProvider.family<List<ReviewModel>, String?>((ref, statusFilter) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getAllReviews(limit: 200, statusFilter: statusFilter);
});

final reviewCountProvider = FutureProvider<int>((ref) async {
  final reviews = await ref.watch(allReviewsAdminProvider(null).future);
  return reviews.length;
});
