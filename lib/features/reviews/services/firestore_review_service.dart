import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/constants/review_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/review_model.dart';
import '../models/review_page_model.dart';

class FirestoreReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  Future<bool> isUserVerified(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    return data['verificationBadge'] != VerificationConstants.badgeNone &&
        data['verificationStatus'] == VerificationConstants.statusApproved;
  }

  Future<ReviewModel> createReview({required ReviewModel review}) async {
    if (!review.isVerifiedStudent) {
      throw ReviewFirestoreException(
        message: 'Only verified students can submit reviews.',
      );
    }

    final id = review.id.isEmpty ? _uuid.v4() : review.id;
    final now = DateTime.now();
    final saved = review.copyWith(
      id: id,
      collegeId: review.collegeId.trim(),
      status: ReviewModel.statusPublished,
      isVerifiedStudent: true,
      createdAt: review.createdAt,
      updatedAt: now,
    );
    final data = saved.toJson();
    data['createdAt'] = saved.createdAt.toIso8601String();
    data['updatedAt'] = now.toIso8601String();

    await _firestore.runTransaction((transaction) async {
      transaction.set(_reviews.doc(id), data);
      await _applyReviewDeltaInTransaction(
        transaction,
        collegeId: review.collegeId.trim(),
        review: saved,
        deltaSign: 1,
      );
    });

    return saved;
  }

  Future<void> updateReview(ReviewModel review, {ReviewModel? previous}) async {
    if (!review.isVerifiedStudent) {
      throw ReviewFirestoreException(
        message: 'Only verified students can update reviews.',
      );
    }

    final data = review.copyWith(updatedAt: DateTime.now()).toJson();
    await _firestore.runTransaction((transaction) async {
      transaction.update(_reviews.doc(review.id), data);
      if (previous != null && previous.isPublicVisible) {
        await _applyReviewDeltaInTransaction(
          transaction,
          collegeId: review.collegeId.trim(),
          review: previous,
          deltaSign: -1,
        );
      }
      if (review.isPublicVisible) {
        await _applyReviewDeltaInTransaction(
          transaction,
          collegeId: review.collegeId.trim(),
          review: review,
          deltaSign: 1,
        );
      }
    });
  }

  Future<void> updateReviewStatus(String reviewId, String status) async {
    final review = await getReviewById(reviewId);
    if (review == null) return;

    await _firestore.runTransaction((transaction) async {
      transaction.update(_reviews.doc(reviewId), {
        'status': ReviewModel.normalizeStatus(status),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final wasVisible = review.isPublicVisible;
      final normalized = ReviewModel.normalizeStatus(status);
      final nowVisible =
          normalized == ReviewModel.statusPublished && review.isVerifiedStudent;

      if (wasVisible && !nowVisible) {
        await _applyReviewDeltaInTransaction(
          transaction,
          collegeId: review.collegeId.trim(),
          review: review,
          deltaSign: -1,
        );
      } else if (!wasVisible && nowVisible) {
        await _applyReviewDeltaInTransaction(
          transaction,
          collegeId: review.collegeId.trim(),
          review: review,
          deltaSign: 1,
        );
      }
    });
  }

  Future<void> deleteReview(String reviewId) async {
    final review = await getReviewById(reviewId);
    if (review == null) {
      await _reviews.doc(reviewId).delete();
      return;
    }

    await _firestore.runTransaction((transaction) async {
      transaction.delete(_reviews.doc(reviewId));
      if (review.isPublicVisible) {
        await _applyReviewDeltaInTransaction(
          transaction,
          collegeId: review.collegeId.trim(),
          review: review,
          deltaSign: -1,
        );
      }
    });
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
    return reviews;
  }

  Query<Map<String, dynamic>> _verifiedCollegeQuery(String collegeId) {
    return _reviews
        .where('collegeId', isEqualTo: collegeId.trim())
        .where('isVerifiedStudent', isEqualTo: true)
        .orderBy('createdAt', descending: true);
  }

  Future<ReviewPage> getReviewsPage(
    String collegeId, {
    String? startAfterDocumentId,
    int limit = ReviewConstants.pageSize,
  }) async {
    final normalizedId = collegeId.trim();
    Query<Map<String, dynamic>> query =
        _verifiedCollegeQuery(normalizedId).limit(limit);

    if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
      final cursor = await _reviews.doc(startAfterDocumentId).get();
      if (cursor.exists) {
        query = query.startAfterDocument(cursor);
      }
    }

    try {
      final snapshot = await query.get();
      final reviews = _parseReviews(snapshot, publicOnly: true);
      final lastId = snapshot.docs.isEmpty ? null : snapshot.docs.last.id;
      return ReviewPage(
        reviews: reviews,
        lastDocumentId: lastId,
        hasMore: snapshot.docs.length >= limit,
      );
    } on FirebaseException {
      final snapshot =
          await _reviews.where('collegeId', isEqualTo: normalizedId).get();
      final all = _parseReviews(snapshot, publicOnly: true);
      return ReviewPage(reviews: all.take(limit).toList(), hasMore: false);
    }
  }

  Stream<List<ReviewModel>> watchReviewsByCollege(String collegeId) {
    final normalizedId = collegeId.trim();
    return _verifiedCollegeQuery(normalizedId)
        .limit(ReviewConstants.pageSize)
        .snapshots()
        .map((snapshot) => _parseReviews(snapshot, publicOnly: true));
  }

  Future<List<ReviewModel>> getReviewsByCollege(String collegeId) async {
    final page = await getReviewsPage(collegeId, limit: 500);
    return page.reviews;
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

  Future<bool> hasMarkedHelpful(String reviewId, String userId) async {
    final doc = await _reviews
        .doc(reviewId)
        .collection(FirestoreConstants.reviewHelpfulSubcollection)
        .doc(userId)
        .get();
    return doc.exists;
  }

  Future<void> markHelpful(String reviewId, String userId) async {
    final helpfulRef = _reviews
        .doc(reviewId)
        .collection(FirestoreConstants.reviewHelpfulSubcollection)
        .doc(userId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(helpfulRef);
      if (existing.exists) {
        throw ReviewFirestoreException(
          message: 'You already marked this helpful.',
        );
      }

      final reviewRef = _reviews.doc(reviewId);
      final reviewSnap = await transaction.get(reviewRef);
      if (!reviewSnap.exists) {
        throw ReviewFirestoreException(message: 'Review not found.');
      }

      transaction.set(helpfulRef, {
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      transaction.update(reviewRef, {
        'helpfulCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> reportReview({
    required String reviewId,
    required String collegeId,
    required String reporterId,
    required String reason,
  }) async {
    await _firestore
        .collection(FirestoreConstants.reviewReportsCollection)
        .add({
      'reviewId': reviewId,
      'collegeId': collegeId.trim(),
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': ReviewConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _applyReviewDeltaInTransaction(
    Transaction transaction, {
    required String collegeId,
    required ReviewModel review,
    required int deltaSign,
  }) async {
    final collegeRef = _colleges.doc(collegeId);
    final collegeSnap = await transaction.get(collegeRef);

    ReviewAggregationMeta meta;
    if (collegeSnap.exists) {
      meta = ReviewAggregationMeta.fromJson(
        collegeSnap.data()?['reviewAggregation'] as Map<String, dynamic>?,
      );
    } else {
      meta = const ReviewAggregationMeta();
    }

    final nextMeta = _applyDeltaToMeta(meta, review, deltaSign);
    final aggregates = _averagesFromMeta(nextMeta);
    final distribution = _distributionFromMeta(nextMeta);

    transaction.set(
      collegeRef,
      {
        'reviewAggregation': nextMeta.toJson(),
        'aggregatedRatings': aggregates,
        'ratingDistribution': distribution,
        'reviewCount': nextMeta.reviewCount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  ReviewAggregationMeta _applyDeltaToMeta(
    ReviewAggregationMeta meta,
    ReviewModel review,
    int deltaSign,
  ) {
    final sums = Map<String, double>.from(meta.dimensionSums);
    final counts = Map<String, int>.from(meta.dimensionCounts);
    final stars = Map<String, int>.from(meta.starDistribution);

    review.ratings.forEach((key, value) {
      if (value <= 0) return;
      sums[key] = (sums[key] ?? 0) + (value * deltaSign);
      counts[key] = ((counts[key] ?? 0) + deltaSign).clamp(0, 999999);
    });

    final star = RatingDistribution.starBucketFor(review.overallRating);
    final starKey = '$star';
    stars[starKey] = ((stars[starKey] ?? 0) + deltaSign).clamp(0, 999999);

    return ReviewAggregationMeta(
      dimensionSums: sums,
      dimensionCounts: counts,
      starDistribution: stars,
      reviewCount: (meta.reviewCount + deltaSign).clamp(0, 999999),
    );
  }

  Map<String, dynamic> _averagesFromMeta(ReviewAggregationMeta meta) {
    double avg(String key) {
      final count = meta.dimensionCounts[key] ?? 0;
      if (count <= 0) return 0;
      return double.parse(
        ((meta.dimensionSums[key] ?? 0) / count).toStringAsFixed(1),
      );
    }

    return {for (final key in RatingParameters.allKeys) key: avg(key)};
  }

  Map<String, int> _distributionFromMeta(ReviewAggregationMeta meta) {
    return {
      for (var i = 1; i <= 5; i++)
        '$i': meta.starDistribution['$i'] ?? 0,
    };
  }

  /// Full recompute fallback for admin/migration.
  Future<void> updateCollegeAggregates(
    String collegeId,
    List<ReviewModel> reviews,
  ) async {
    var meta = const ReviewAggregationMeta();
    for (final review in reviews.where((r) => r.isPublicVisible)) {
      meta = _applyDeltaToMeta(meta, review, 1);
    }

    await _colleges.doc(collegeId.trim()).set({
      'reviewAggregation': meta.toJson(),
      'aggregatedRatings': _averagesFromMeta(meta),
      'ratingDistribution': _distributionFromMeta(meta),
      'reviewCount': meta.reviewCount,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}

class ReviewFirestoreException implements Exception {
  final String message;
  ReviewFirestoreException({required this.message});
  @override
  String toString() => message;
}

String generateAnonymousAlias(String userId, {required bool isAnonymous}) {
  final hash = userId.hashCode.abs() % 10000;
  if (isAnonymous) {
    return 'Verified Student #$hash';
  }
  return 'Student #$hash';
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
    campusLife: avg(RatingParameters.sports),
    hostel: avg(RatingParameters.hostel),
    fees: avg(RatingParameters.food),
    teaching: avg(RatingParameters.teaching),
    labs: avg(RatingParameters.labs),
    library: avg(RatingParameters.library),
    sports: avg(RatingParameters.sports),
    food: avg(RatingParameters.food),
    attendance: avg(RatingParameters.attendance),
    safety: avg(RatingParameters.safety),
  );
}
