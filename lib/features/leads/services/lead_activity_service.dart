import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';

/// Event types written to `lead_activity_events`. A Firestore trigger
/// (functions/src/leadActivityTriggers.js) rolls each new event into the
/// caller's `lead_summaries/{uid}` doc -- see that file for exactly how
/// "interested faculty" and "last active" get derived from these.
class LeadEventType {
  LeadEventType._();
  static const String search = 'search';
  static const String view = 'view';
  static const String call = 'call';
  static const String message = 'message';
}

/// Logs a student's college-interest activity (search-by-faculty, college
/// detail view, calling a college) for the Super Admin panel's Weekly Lead
/// Analytics screen. Every call here is fire-and-forget from the caller's
/// perspective: a logging failure must never interrupt the actual user
/// action (a search, opening a page, dialing a number) it's attached to,
/// so every method swallows its own errors rather than throwing.
class LeadActivityService {
  LeadActivityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(FirestoreConstants.leadActivityEventsCollection);

  Future<void> _log({
    required String userId,
    required String eventType,
    String? faculty,
    String? collegeId,
    String? collegeName,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _events.doc(_uuid.v4()).set({
        'userId': userId,
        'eventType': eventType,
        if (faculty != null && faculty.isNotEmpty) 'faculty': faculty,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        if (collegeName != null && collegeName.isNotEmpty) 'collegeName': collegeName,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Best-effort -- see class doc.
    }
  }

  /// A student picked [faculty] (Engineering/MBA/Law/...) in the college
  /// search filters -- see CollegeConstants.collegeCategories, the same
  /// list this Faculty filter and the admin panel's Faculty dropdown share.
  Future<void> logSearch({required String userId, required String faculty}) {
    return _log(userId: userId, eventType: LeadEventType.search, faculty: faculty);
  }

  /// A student opened a college's detail page.
  Future<void> logCollegeView({
    required String userId,
    required String collegeId,
    required String collegeName,
    String? faculty,
  }) {
    return _log(
      userId: userId,
      eventType: LeadEventType.view,
      collegeId: collegeId,
      collegeName: collegeName,
      faculty: faculty,
    );
  }

  /// A student tapped "Call" on a college's contact number.
  Future<void> logCallCollege({
    required String userId,
    required String collegeId,
    required String collegeName,
    String? faculty,
  }) {
    return _log(
      userId: userId,
      eventType: LeadEventType.call,
      collegeId: collegeId,
      collegeName: collegeName,
      faculty: faculty,
    );
  }
}
