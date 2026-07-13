import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../colleges/services/firestore_college_service.dart';
import 'admin_college_bulk_service.dart';
import '../models/admin_models.dart';
import '../utils/admin_analytics_utils.dart';

class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _collegeService = FirestoreCollegeService();
  final _bulkService = AdminCollegeBulkService();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreConstants.usersCollection);
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreConstants.reviewsCollection);
  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection(FirestoreConstants.collegeQuestionsCollection);
  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);
  CollectionReference<Map<String, dynamic>> get _analyticsEvents =>
      _firestore.collection(FirestoreConstants.collegeAnalyticsEventsCollection);

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Future<AdminDashboardStats> fetchDashboardStats() async {
    final now = DateTime.now();

    final results = await Future.wait([
      _count(_colleges.where('isActive', isEqualTo: true)),
      _count(_reviews),
      _count(_questions.where('status', isEqualTo: QuestionConstants.statusPublished)),
      _countVerifiedStudents(),
      _countTotalAnswers(),
      _countOpenReports(),
      _fetchActiveUserCounts(),
    ]);

    final activeCounts = results[6] as (int, int);

    return AdminDashboardStats(
      totalColleges: results[0] as int,
      totalReviews: results[1] as int,
      totalQuestions: results[2] as int,
      verifiedStudents: results[3] as int,
      totalAnswers: results[4] as int,
      totalReports: results[5] as int,
      dailyActiveUsers: activeCounts.$1,
      monthlyActiveUsers: activeCounts.$2,
      fetchedAt: now,
    );
  }

  Future<int> _countVerifiedStudents() async {
    return _count(
      _users
          .where('verificationStatus', isEqualTo: VerificationConstants.statusApproved)
          .where('verificationBadge', isNotEqualTo: VerificationConstants.badgeNone),
    );
  }

  Future<int> _countTotalAnswers() async {
    final snap = await _questions.limit(AdminConstants.analyticsSampleLimit).get();
    var total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['answerCount'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  Future<int> _countOpenReports() async {
    final counts = await Future.wait<int>([
      _countOpenIn(FirestoreConstants.reviewReportsCollection),
      _countOpenIn(FirestoreConstants.userReportsCollection),
      _countOpenIn(FirestoreConstants.communityReportsCollection),
      _countOpenIn(FirestoreConstants.questionReportsCollection),
      _countOpenIn(FirestoreConstants.answerReportsCollection),
      _countOpenIn(FirestoreConstants.studentCommunityPostReportsCollection),
      _countOpenIn(FirestoreConstants.studentCommunityCommentReportsCollection),
    ]);
    return counts.fold<int>(0, (a, b) => a + b);
  }

  Future<int> _countOpenIn(String collection) async {
    return _count(
      _firestore.collection(collection).where('status', isEqualTo: AdminConstants.reportStatusOpen),
    );
  }

  Future<(int, int)> _fetchActiveUserCounts() async {
    final snap = await _users
        .orderBy('updatedAt', descending: true)
        .limit(AdminConstants.analyticsSampleLimit)
        .get();

    final lastSeenTimes = snap.docs.map((d) {
      final presence = d.data()['presence'] as Map<String, dynamic>?;
      final lastSeen = presence?['lastSeenAt']?.toString();
      return lastSeen != null ? DateTime.tryParse(lastSeen) : null;
    }).toList();

    return (
      countActiveSince(lastSeenTimes, const Duration(days: 1)),
      countActiveSince(lastSeenTimes, const Duration(days: 30)),
    );
  }

  Future<AdminAnalyticsData> fetchAnalyticsData() async {
    final now = DateTime.now();

    final reviewSnap = await _reviews
        .orderBy('createdAt', descending: true)
        .limit(AdminConstants.analyticsSampleLimit)
        .get();
    final userSnap = await _users
        .orderBy('createdAt', descending: true)
        .limit(AdminConstants.analyticsSampleLimit)
        .get();
    final collegeSnap = await _colleges
        .orderBy('updatedAt', descending: true)
        .limit(AdminConstants.analyticsSampleLimit)
        .get();

    final reviewDates = reviewSnap.docs
        .map((d) => DateTime.tryParse(d.data()['createdAt']?.toString() ?? ''))
        .whereType<DateTime>()
        .toList();
    final userDates = userSnap.docs
        .map((d) => DateTime.tryParse(d.data()['createdAt']?.toString() ?? ''))
        .whereType<DateTime>()
        .toList();
    final collegeDates = collegeSnap.docs
        .map((d) => DateTime.tryParse(d.data()['createdAt']?.toString() ?? ''))
        .whereType<DateTime>()
        .toList();

    final eventSnap = await _analyticsEvents
        .orderBy('count', descending: true)
        .limit(20)
        .get();

    final viewMetrics = <AdminTopCollegeMetric>[];
    final searchMetrics = <AdminTopCollegeMetric>[];
    final collegeNames = <String, String>{};

    for (final doc in collegeSnap.docs) {
      collegeNames[doc.id] = doc.data()['name']?.toString() ?? doc.id;
    }

    for (final doc in eventSnap.docs) {
      final data = doc.data();
      final collegeId = data['collegeId']?.toString() ?? '';
      final count = (data['count'] as num?)?.toInt() ?? 0;
      final eventType = data['eventType']?.toString() ?? '';
      final name = collegeNames[collegeId] ?? collegeId;
      final metric = AdminTopCollegeMetric(
        collegeId: collegeId,
        collegeName: name,
        value: count,
        label: eventType,
      );
      if (eventType == 'view') {
        viewMetrics.add(metric);
      } else if (eventType == 'search') {
        searchMetrics.add(metric);
      }
    }

    final bookmarkCounts = <String, int>{};
    final usersForBookmarks = await _users.limit(100).get();
    for (final doc in usersForBookmarks.docs) {
      final ids = (doc.data()['favoriteCollegeIds'] as List<dynamic>?)?.cast<String>() ?? [];
      for (final id in ids) {
        bookmarkCounts[id] = (bookmarkCounts[id] ?? 0) + 1;
      }
    }

    return AdminAnalyticsData(
      reviewGrowth: buildDailyGrowthSeries(timestamps: reviewDates),
      userGrowth: buildDailyGrowthSeries(timestamps: userDates),
      collegeGrowth: buildDailyGrowthSeries(timestamps: collegeDates),
      mostViewed: viewMetrics.take(10).toList(),
      mostSearched: searchMetrics.take(10).toList(),
      mostBookmarked: rankBookmarkCounts(bookmarkCounts, collegeNames),
      fetchedAt: now,
    );
  }

  Future<List<AdminReportSummary>> fetchOpenReports({int limit = 100}) async {
    final reports = <AdminReportSummary>[];

    Future<void> load(String collection, String source, String entityField) async {
      final snap = await _firestore
          .collection(collection)
          .where('status', isEqualTo: AdminConstants.reportStatusOpen)
          .orderBy('createdAt', descending: true)
          .limit(limit ~/ 7 + 1)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        reports.add(AdminReportSummary(
          source: source,
          reportId: doc.id,
          reason: data['reason']?.toString() ?? '',
          status: data['status']?.toString() ?? '',
          entityId: data[entityField]?.toString() ?? '',
          createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
        ));
      }
    }

    await Future.wait([
      load(FirestoreConstants.reviewReportsCollection, 'Review', 'reviewId'),
      load(FirestoreConstants.userReportsCollection, 'Communication', 'reportedId'),
      load(FirestoreConstants.communityReportsCollection, 'Community', 'messageId'),
      load(FirestoreConstants.questionReportsCollection, 'Question', 'questionId'),
      load(FirestoreConstants.answerReportsCollection, 'Answer', 'answerId'),
      load(FirestoreConstants.studentCommunityPostReportsCollection, 'Campus Post', 'postId'),
      load(FirestoreConstants.studentCommunityCommentReportsCollection, 'Campus Comment', 'commentId'),
    ]);

    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports.take(limit).toList();
  }

  Future<void> updateReportStatus({
    required String collection,
    required String reportId,
    required String status,
  }) async {
    await _firestore.collection(collection).doc(reportId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<AdminSystemHealth> fetchSystemHealth() async {
    final meta = await _firestore
        .collection(FirestoreConstants.metaCollection)
        .doc(AdminConstants.metaSystemHealthDoc)
        .get();

    if (meta.exists) {
      final data = meta.data()!;
      return AdminSystemHealth(
        estimatedFirestoreReads: (data['estimatedFirestoreReads'] as num?)?.toInt() ?? 0,
        estimatedStorageMb: (data['estimatedStorageMb'] as num?)?.toInt() ?? 0,
        crashCount24h: (data['crashCount24h'] as num?)?.toInt() ?? 0,
        avgResponseMs: (data['avgResponseMs'] as num?)?.toDouble() ?? 0,
        errorLogCount: (data['errorLogCount'] as num?)?.toInt() ?? 0,
        fetchedAt: DateTime.now(),
      );
    }

    final collegeCount = await _count(_colleges);
    return AdminSystemHealth(
      estimatedFirestoreReads: collegeCount * 10,
      estimatedStorageMb: collegeCount * 2,
      crashCount24h: 0,
      avgResponseMs: 120,
      errorLogCount: 0,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> fetchCollegeStatsForExport({int limit = 200}) async {
    final snap = await _colleges
        .where('isActive', isEqualTo: true)
        .orderBy('aggregatedRatings.overall', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      final ratings = data['aggregatedRatings'] as Map<String, dynamic>?;
      return {
        'id': d.id,
        'name': data['name'],
        'city': data['city'],
        'state': data['state'],
        'type': data['type'],
        'overall': ratings?['overall'] ?? 0,
        'reviewCount': data['reviewCount'] ?? 0,
        'isActive': data['isActive'] ?? true,
      };
    }).toList();
  }

  Future<int> importCollegesFromCsvRows(List<Map<String, String>> rows) async {
    final colleges = rows
        .map((row) => _bulkService.collegeFromCsvRow(row))
        .where((c) => c.name.isNotEmpty)
        .toList();
    if (colleges.isEmpty) return 0;
    await _collegeService.batchUpsertColleges(colleges);
    return colleges.length;
  }
}
