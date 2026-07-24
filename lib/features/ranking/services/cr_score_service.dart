import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/services/firestore_review_service.dart';

/// Admin and batch CR Score recalculation.
class CrScoreService {
  CrScoreService({
    FirebaseFirestore? firestore,
    FirestoreReviewService? reviewService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _reviewService = reviewService ?? FirestoreReviewService();

  final FirebaseFirestore _firestore;
  final FirestoreReviewService _reviewService;

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  Future<int> recalculateCollege(String collegeId) async {
    final reviews = await _fetchEligibleReviews(collegeId);
    await _reviewService.updateCollegeAggregates(collegeId, reviews);
    return reviews.length;
  }

  Future<CrScoreRecalculateResult> recalculateAllColleges({
    void Function(int processed, int total)? onProgress,
  }) async {
    final snapshot = await _colleges.where('isActive', isEqualTo: true).get();
    final docs = snapshot.docs;
    var processed = 0;
    var reviewTotal = 0;

    for (final doc in docs) {
      final reviews = await _fetchEligibleReviews(doc.id);
      await _reviewService.updateCollegeAggregates(doc.id, reviews);
      processed++;
      reviewTotal += reviews.length;
      onProgress?.call(processed, docs.length);
    }

    return CrScoreRecalculateResult(
      collegesProcessed: processed,
      eligibleReviewsProcessed: reviewTotal,
    );
  }

  Future<List<ReviewModel>> _fetchEligibleReviews(String collegeId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.reviewsCollection)
        .where('collegeId', isEqualTo: collegeId.trim())
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data(), docId: doc.id))
        .where((review) => review.isPublicVisible)
        .toList();
  }
}

class CrScoreRecalculateResult {
  final int collegesProcessed;
  final int eligibleReviewsProcessed;

  const CrScoreRecalculateResult({
    required this.collegesProcessed,
    required this.eligibleReviewsProcessed,
  });
}

final crScoreServiceProvider = Provider<CrScoreService>((ref) {
  return CrScoreService();
});
