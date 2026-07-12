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

final collegeReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, collegeId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.watchReviewsByCollege(collegeId);
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

final allReviewsAdminProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getAllReviews(limit: 200);
});

final reviewCountProvider = FutureProvider<int>((ref) async {
  final reviews = await ref.watch(allReviewsAdminProvider.future);
  return reviews.length;
});
