import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/ranking_models.dart';

class FirestoreRankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  CollectionReference<Map<String, dynamic>> get _analyticsEvents =>
      _firestore.collection(FirestoreConstants.collegeAnalyticsEventsCollection);

  Future<RankingPageResult> fetchRankedCollegesPage({
    String? state,
    String? city,
    String? course,
    String? collegeType,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = RankingConstants.defaultPageSize,
  }) async {
    Query<Map<String, dynamic>> query = _colleges.where('isActive', isEqualTo: true);

    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (course != null && course.isNotEmpty) {
      query = query.where('courses', arrayContains: course);
    }
    if (collegeType != null && collegeType.isNotEmpty) {
      query = query.where('type', isEqualTo: collegeType);
    }

    query = query.orderBy('aggregatedRatings.overall', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final colleges = snap.docs
        .map((d) => CollegeModel.fromJson(d.data(), docId: d.id))
        .toList();

    return RankingPageResult(
      colleges: colleges,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<CollegeModel>> fetchFeaturedForRanking({int limit = 100}) async {
    final snap = await _colleges
        .where('isActive', isEqualTo: true)
        .orderBy('aggregatedRatings.overall', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => CollegeModel.fromJson(d.data(), docId: d.id)).toList();
  }

  Future<Map<String, int>> fetchSearchCounts() async {
    final snap = await _analyticsEvents
        .where('eventType', isEqualTo: 'search')
        .orderBy('count', descending: true)
        .limit(50)
        .get();
    return {
      for (final doc in snap.docs)
        doc.data()['collegeId'] as String? ?? '': (doc.data()['count'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> recordCollegeEvent({
    required String collegeId,
    required String eventType,
    required String userId,
  }) async {
    final docId = '${collegeId}_$eventType';
    final ref = _analyticsEvents.doc(docId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {
          'count': FieldValue.increment(1),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        tx.set(ref, {
          'collegeId': collegeId,
          'eventType': eventType,
          'count': 1,
          'lastUserId': userId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    });
  }
}
