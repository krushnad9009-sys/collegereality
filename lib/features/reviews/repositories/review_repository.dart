import '../models/review_model.dart';
import '../models/review_page_model.dart';
import '../services/firestore_review_service.dart';

abstract class ReviewRepository {
  Future<ReviewModel> submitReview(ReviewModel review);
  Future<void> updateReview(ReviewModel review);
  Future<void> updateReviewStatus(String reviewId, String collegeId, String status);
  Future<void> deleteReview(String reviewId, String collegeId);
  Future<ReviewModel?> getUserReviewForCollege(String userId, String collegeId);
  Future<ReviewPage> getReviewsPage(
    String collegeId, {
    String? startAfterDocumentId,
  });
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
    return _service.createReview(review: review);
  }

  @override
  Future<void> updateReview(ReviewModel review) async {
    final previous = await _service.getReviewById(review.id);
    await _service.updateReview(review, previous: previous);
  }

  @override
  Future<void> updateReviewStatus(
    String reviewId,
    String collegeId,
    String status,
  ) async {
    await _service.updateReviewStatus(reviewId, status);
  }

  @override
  Future<void> deleteReview(String reviewId, String collegeId) async {
    await _service.deleteReview(reviewId);
  }

  @override
  Future<ReviewModel?> getUserReviewForCollege(
    String userId,
    String collegeId,
  ) {
    return _service.getUserReviewForCollege(userId, collegeId);
  }

  @override
  Future<ReviewPage> getReviewsPage(
    String collegeId, {
    String? startAfterDocumentId,
  }) {
    return _service.getReviewsPage(
      collegeId,
      startAfterDocumentId: startAfterDocumentId,
    );
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
}
