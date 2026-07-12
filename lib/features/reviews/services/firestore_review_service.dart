import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../colleges/models/college_model.dart';
import '../models/review_model.dart';

class FirestoreReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  Future<ReviewModel> createReview({
    required ReviewModel review,
  }) async {
    final id = review.id.isEmpty ? _uuid.v4() : review.id;
    final now = DateTime.now();
    final data = review
        .copyWith(
          id: id,
          collegeId: review.collegeId.trim(),
          status: ReviewModel.statusPublished,
          createdAt: review.createdAt,
          updatedAt: now,
        )
        .toJson();
    data['createdAt'] = review.createdAt.toIso8601String();
    data['updatedAt'] = now.toIso8601String();
    await _reviews.doc(id).set(data);
    return ReviewModel.fromJson(data, docId: id);
  }

  Future<void> updateReview(ReviewModel review) async {
    final data = review.copyWith(updatedAt: DateTime.now()).toJson();
    await _reviews.doc(review.id).update(data);
  }

  Future<void> updateReviewStatus(String reviewId, String status) async {
    await _reviews.doc(reviewId).update({
      'status': ReviewModel.normalizeStatus(status),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _reviews.doc(reviewId).delete();
  }

  Future<ReviewModel?> getReviewById(String reviewId) async {
    final doc = await _reviews.doc(reviewId).get();
    if (!doc.exists) return null;
    return ReviewModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<ReviewModel?> getUserReviewForCollege(
    String userId,
    String collegeId,
  ) async {
    final snapshot = await _reviews
        .where('userId', isEqualTo: userId)
        .where('collegeId', isEqualTo: collegeId.trim())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ReviewModel.fromJson(doc.data(), docId: doc.id);
  }

  List<ReviewModel> _parseReviews(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    bool publicOnly = false,
  }) {
    final reviews = <ReviewModel>[];
    for (final doc in snapshot.docs) {
      try {
        final review = ReviewModel.fromJson(doc.data(), docId: doc.id);
        if (!publicOnly || review.isPublicVisible) {
          reviews.add(review);
        }
      } catch (_) {
        // Skip malformed documents.
      }
    }
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<List<ReviewModel>> getReviewsByCollege(String collegeId) async {
    final normalizedId = collegeId.trim();
    try {
      final snapshot = await _reviews
          .where('collegeId', isEqualTo: normalizedId)
          .orderBy('createdAt', descending: true)
          .get();
      return _parseReviews(snapshot, publicOnly: true);
    } on FirebaseException {
      final snapshot =
          await _reviews.where('collegeId', isEqualTo: normalizedId).get();
      return _parseReviews(snapshot, publicOnly: true);
    }
  }

  Stream<List<ReviewModel>> watchReviewsByCollege(String collegeId) {
    final normalizedId = collegeId.trim();
    return _reviews
        .where('collegeId', isEqualTo: normalizedId)
        .snapshots()
        .map((snapshot) => _parseReviews(snapshot, publicOnly: true));
  }

  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final snapshot = await _reviews
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return _parseReviews(snapshot);
    } on FirebaseException {
      final snapshot = await _reviews.where('userId', isEqualTo: userId).get();
      return _parseReviews(snapshot);
    }
  }

  Future<List<ReviewModel>> getAllReviews({
    int limit = 100,
    String? statusFilter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _reviews.orderBy(
        'createdAt',
        descending: true,
      );
      if (statusFilter != null) {
        query = query.where(
          'status',
          isEqualTo: ReviewModel.normalizeStatus(statusFilter),
        );
      }
      final snapshot = await query.limit(limit).get();
      return _parseReviews(snapshot);
    } on FirebaseException {
      final snapshot = await _reviews.limit(limit).get();
      var reviews = _parseReviews(snapshot);
      if (statusFilter != null) {
        final normalized = ReviewModel.normalizeStatus(statusFilter);
        reviews = reviews.where((r) => r.status == normalized).toList();
      }
      return reviews.take(limit).toList();
    }
  }

  Future<void> incrementLikeCount(String reviewId) async {
    await _reviews.doc(reviewId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  Future<void> updateCollegeAggregates(
    String collegeId,
    List<ReviewModel> reviews,
  ) async {
    final aggregates = _computeAggregates(reviews);
    await _colleges.doc(collegeId.trim()).update({
      'aggregatedRatings': aggregates,
      'reviewCount': reviews.length,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _computeAggregates(List<ReviewModel> reviews) {
    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final review in reviews) {
      review.ratings.forEach((key, value) {
        if (value > 0) {
          sums[key] = (sums[key] ?? 0) + value;
          counts[key] = (counts[key] ?? 0) + 1;
        }
      });
    }

    double avg(String key) {
      final count = counts[key] ?? 0;
      if (count == 0) return 0;
      return double.parse(((sums[key] ?? 0) / count).toStringAsFixed(1));
    }

    return {
      'overall': avg(RatingParameters.overall),
      'faculty': avg(RatingParameters.faculty),
      'hostel': avg(RatingParameters.hostel),
      'placements': avg(RatingParameters.placements),
      'fees': avg(RatingParameters.fees),
      'infrastructure': avg(RatingParameters.infrastructure),
      'campusLife': avg(RatingParameters.campusLife),
    };
  }
}

class ReviewFirestoreException implements Exception {
  final String message;
  ReviewFirestoreException({required this.message});
  @override
  String toString() => message;
}

CollegeRatings computeCollegeRatingsFromReviews(List<ReviewModel> reviews) {
  if (reviews.isEmpty) {
    return const CollegeRatings(
      overall: 0,
      faculty: 0,
      infrastructure: 0,
      placements: 0,
      campusLife: 0,
    );
  }

  double avg(String key) {
    final values = reviews
        .map((r) => r.ratings[key] ?? 0)
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return 0;
    return double.parse(
      (values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1),
    );
  }

  return CollegeRatings(
    overall: avg(RatingParameters.overall),
    faculty: avg(RatingParameters.faculty),
    infrastructure: avg(RatingParameters.infrastructure),
    placements: avg(RatingParameters.placements),
    campusLife: avg(RatingParameters.campusLife),
  );
}

String generateAnonymousAlias(String userId) {
  final hash = userId.hashCode.abs() % 10000;
  return 'Verified Student #$hash';
}
