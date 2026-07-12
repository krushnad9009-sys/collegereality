import '../models/review_model.dart';
import '../services/firestore_review_service.dart';

abstract class ReviewRepository {
  Future<ReviewModel> submitReview(ReviewModel review);
  Future<void> updateReview(ReviewModel review);
  Future<void> updateReviewStatus(String reviewId, String collegeId, String status);
  Future<void> deleteReview(String reviewId, String collegeId);
  Future<ReviewModel?> getUserReviewForCollege(String userId, String collegeId);
  Future<List<ReviewModel>> getReviewsByCollege(String collegeId);
  Stream<List<ReviewModel>> watchReviewsByCollege(String collegeId);
  Future<List<ReviewModel>> getReviewsByUser(String userId);
  Future<List<ReviewModel>> getAllReviews({int limit = 100, String? statusFilter});
  Future<bool> hasMarkedHelpful(String reviewId, String userId);
  Future<void> markHelpful(String reviewId, String userId);
  Future<void> reportReview({
    required String reviewId,
    required String collegeId,
    required String reporterId,
    required String reason,
  });
  Future<bool> isUserVerified(String userId);
}

class ReviewRepositoryImpl implements ReviewRepository {
  final FirestoreReviewService _service;

  ReviewRepositoryImpl(this._service);

  @override
  Future<bool> isUserVerified(String userId) => _service.isUserVerified(userId);

  @override
  Future<ReviewModel> submitReview(ReviewModel review) async {
    final created = await _service.createReview(review: review);
    await _refreshCollegeAggregates(review.collegeId);
    return created;
  }

  @override
  Future<void> updateReview(ReviewModel review) async {
    await _service.updateReview(review);
    await _refreshCollegeAggregates(review.collegeId);
  }

  @override
  Future<void> updateReviewStatus(
    String reviewId,
    String collegeId,
    String status,
  ) async {
    await _service.updateReviewStatus(reviewId, status);
    await _refreshCollegeAggregates(collegeId);
  }

  @override
  Future<void> deleteReview(String reviewId, String collegeId) async {
    await _service.deleteReview(reviewId);
    await _refreshCollegeAggregates(collegeId);
  }

  @override
  Future<ReviewModel?> getUserReviewForCollege(
    String userId,
    String collegeId,
  ) {
    return _service.getUserReviewForCollege(userId, collegeId);
  }

  @override
  Future<List<ReviewModel>> getReviewsByCollege(String collegeId) {
    return _service.getReviewsByCollege(collegeId);
  }

  @override
  Stream<List<ReviewModel>> watchReviewsByCollege(String collegeId) {
    return _service.watchReviewsByCollege(collegeId);
  }

  @override
  Future<List<ReviewModel>> getReviewsByUser(String userId) {
    return _service.getReviewsByUser(userId);
  }

  @override
  Future<List<ReviewModel>> getAllReviews({
    int limit = 100,
    String? statusFilter,
  }) {
    return _service.getAllReviews(limit: limit, statusFilter: statusFilter);
  }

  @override
  Future<bool> hasMarkedHelpful(String reviewId, String userId) {
    return _service.hasMarkedHelpful(reviewId, userId);
  }

  @override
  Future<void> markHelpful(String reviewId, String userId) {
    return _service.markHelpful(reviewId, userId);
  }

  @override
  Future<void> reportReview({
    required String reviewId,
    required String collegeId,
    required String reporterId,
    required String reason,
  }) {
    return _service.reportReview(
      reviewId: reviewId,
      collegeId: collegeId,
      reporterId: reporterId,
      reason: reason,
    );
  }

  Future<void> _refreshCollegeAggregates(String collegeId) async {
    try {
      final reviews = await _service.getReviewsByCollege(collegeId);
      await _service.updateCollegeAggregates(collegeId, reviews);
    } catch (_) {
      // Best-effort aggregate update.
    }
  }
}
