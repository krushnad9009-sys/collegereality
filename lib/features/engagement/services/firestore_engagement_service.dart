import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/engagement_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../models/engagement_models.dart';
import '../utils/alert_scanner.dart';
import '../utils/engagement_filter_utils.dart';

class FirestoreEngagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreConstants.userNotificationsCollection);
  CollectionReference<Map<String, dynamic>> get _preferences =>
      _firestore.collection(FirestoreConstants.notificationPreferencesCollection);
  CollectionReference<Map<String, dynamic>> get _calendar =>
      _firestore.collection(FirestoreConstants.admissionCalendarEventsCollection);
  CollectionReference<Map<String, dynamic>> get _savedExams =>
      _firestore.collection(FirestoreConstants.savedEntranceExamsCollection);
  CollectionReference<Map<String, dynamic>> get _savedQuestions =>
      _firestore.collection(FirestoreConstants.savedQuestionsCollection);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreConstants.usersCollection);
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreConstants.reviewsCollection);
  CollectionReference<Map<String, dynamic>> get _scholarships =>
      _firestore.collection(FirestoreConstants.scholarshipsCollection);
  CollectionReference<Map<String, dynamic>> get _campusEvents =>
      _firestore.collection(FirestoreConstants.campusEventsCollection);
  DocumentReference<Map<String, dynamic>> get _meta =>
      _firestore.collection(FirestoreConstants.metaCollection).doc(
            EngagementConstants.metaEngagementSeededDoc,
          );

  Future<void> ensureSeeded() async {
    final meta = await _meta.get();
    if (meta.exists && meta.data()?['seeded'] == true) return;
    final snap = await _calendar.limit(1).get();
    if (snap.docs.isNotEmpty) {
      await _meta.set({'seeded': true, 'updatedAt': DateTime.now().toIso8601String()});
      return;
    }
    await _seedCalendarFromAssets();
    await _meta.set({'seeded': true, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<void> _seedCalendarFromAssets() async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    final json = await rootBundle.loadString('assets/data/admission_calendar_seed.json');
    for (final item in jsonDecode(json) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildEngagementSearchText([
        map['title'] as String? ?? '',
        map['category'] as String? ?? '',
        map['state'] as String? ?? '',
        map['description'] as String? ?? '',
      ]);
      map['isActive'] = true;
      map['updatedAt'] = now.toIso8601String();
      batch.set(_calendar.doc(id), map);
    }
    await batch.commit();
  }

  Stream<List<UserNotificationModel>> watchUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserNotificationModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> createNotification(UserNotificationModel notification) async {
    final id = notification.id.isNotEmpty ? notification.id : _uuid.v4();
    final data = notification.copyWith().toJson();
    data['id'] = id;
    if ((data['searchText'] as String?)?.isEmpty ?? true) {
      data['searchText'] = buildEngagementSearchText([
        notification.title,
        notification.body,
        notification.type,
        notification.category,
      ]);
    }
    await _notifications.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> createNotificationFromDraft({
    required String userId,
    required AlertNotificationDraft draft,
  }) async {
    final dedupeDocId = dedupeKey(userId, draft.type, draft.entityId);
    final existing = await _notifications.doc(dedupeDocId).get();
    if (existing.exists) return;

    await _notifications.doc(dedupeDocId).set({
      'id': dedupeDocId,
      'userId': userId,
      'type': draft.type,
      'category': draft.category,
      'title': draft.title,
      'body': draft.body,
      'entityType': draft.entityType,
      'entityId': draft.entityId,
      'actionRoute': draft.actionRoute,
      'isRead': false,
      'searchText': buildEngagementSearchText([
        draft.title,
        draft.body,
        draft.type,
        draft.category,
      ]),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .limit(50)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  Future<NotificationPreferencesModel> getOrCreatePreferences(String userId) async {
    final doc = await _preferences.doc(userId).get();
    if (doc.exists) {
      return NotificationPreferencesModel.fromJson(doc.data()!, docId: userId);
    }
    final defaults = NotificationPreferencesModel.defaults(userId);
    await _preferences.doc(userId).set(defaults.toJson());
    return defaults;
  }

  Stream<NotificationPreferencesModel> watchPreferences(String userId) {
    return _preferences.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return NotificationPreferencesModel.defaults(userId);
      }
      return NotificationPreferencesModel.fromJson(doc.data()!, docId: userId);
    });
  }

  Future<void> updatePreferences(NotificationPreferencesModel prefs) async {
    await _preferences.doc(prefs.userId).set(
          prefs.copyWith(updatedAt: DateTime.now()).toJson(),
          SetOptions(merge: true),
        );
  }

  Stream<List<AdmissionCalendarEventModel>> watchCalendarEvents() {
    return _calendar
        .where('isActive', isEqualTo: true)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdmissionCalendarEventModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Future<List<AdmissionCalendarEventModel>> getCalendarEvents() async {
    final snap = await _calendar
        .where('isActive', isEqualTo: true)
        .orderBy('eventDate', descending: false)
        .get();
    return snap.docs
        .map((d) => AdmissionCalendarEventModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  // College bookmarks via users.favoriteCollegeIds
  Stream<Set<String>> watchFavoriteCollegeIds(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return <String>{};
      final ids = doc.data()?['favoriteCollegeIds'] as List<dynamic>?;
      return ids?.cast<String>().toSet() ?? {};
    });
  }

  Future<void> toggleFavoriteCollege(String userId, String collegeId) async {
    final doc = await _users.doc(userId).get();
    final current = (doc.data()?['favoriteCollegeIds'] as List<dynamic>?)
            ?.cast<String>()
            .toList() ??
        <String>[];
    if (current.contains(collegeId)) {
      current.remove(collegeId);
    } else {
      current.add(collegeId);
    }
    await _users.doc(userId).update({
      'favoriteCollegeIds': current,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveFcmToken(String userId, String token) async {
    if (token.isEmpty) return;
    await _users.doc(userId).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // Saved entrance exams
  Future<void> saveEntranceExam(String userId, String examId) async {
    await _savedExams.doc('${userId}_$examId').set({
      'userId': userId,
      'examId': examId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveEntranceExam(String userId, String examId) async {
    await _savedExams.doc('${userId}_$examId').delete();
  }

  Stream<Set<String>> watchSavedExamIds(String userId) {
    return _savedExams
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['examId'] as String).toSet());
  }

  // Saved questions
  Future<void> saveQuestion(String userId, String questionId, {String? collegeId}) async {
    await _savedQuestions.doc('${userId}_$questionId').set({
      'userId': userId,
      'questionId': questionId,
      if (collegeId != null) 'collegeId': collegeId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveQuestion(String userId, String questionId) async {
    await _savedQuestions.doc('${userId}_$questionId').delete();
  }

  Stream<Set<String>> watchSavedQuestionIds(String userId) {
    return _savedQuestions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['questionId'] as String).toSet());
  }

  /// On-demand personalized alert scan — called when notification center opens.
  Future<void> runPersonalizedAlertScan(String userId) async {
    final prefs = await getOrCreatePreferences(userId);
    if (!prefs.alertsEnabled) return;

    final now = DateTime.now();
    final since = prefs.lastAlertScanAt ?? now.subtract(const Duration(days: 7));

    final userDoc = await _users.doc(userId).get();
    final savedCollegeIds =
        (userDoc.data()?['favoriteCollegeIds'] as List<dynamic>?)?.cast<String>().toSet() ??
            {};

    final calendar = await getCalendarEvents();
    final calendarDrafts = buildCalendarAlertDrafts(events: calendar, now: now);

    final scholarshipSnap = await _scholarships
        .where('isActive', isEqualTo: true)
        .limit(20)
        .get();
    final scholarshipDrafts = buildScholarshipOpenDrafts(
      scholarships: scholarshipSnap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
      since: since,
    );

    final eventSnap = await _campusEvents
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(15)
        .get();
    final eventDrafts = buildNewEventDrafts(
      events: eventSnap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
      since: since,
    );

    final reviewDrafts = <AlertNotificationDraft>[];
    if (savedCollegeIds.isNotEmpty && prefs.newReview) {
      for (final collegeId in savedCollegeIds.take(5)) {
        final reviewSnap = await _reviews
            .where('collegeId', isEqualTo: collegeId)
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get();
        reviewDrafts.addAll(
          buildNewReviewDrafts(
            reviews: reviewSnap.docs
                .where((d) {
                  final created = DateTime.tryParse(d.data()['createdAt']?.toString() ?? '');
                  return created != null && created.isAfter(since);
                })
                .map((d) => {...d.data(), 'id': d.id})
                .toList(),
            savedCollegeIds: savedCollegeIds,
          ),
        );
      }
    }

    final allDrafts = [
      ...calendarDrafts,
      ...scholarshipDrafts,
      ...eventDrafts,
      ...reviewDrafts,
    ];

    for (final draft in allDrafts) {
      if (!isPreferenceEnabled(prefs, draft.type)) continue;
      await createNotificationFromDraft(userId: userId, draft: draft);
    }

    await updatePreferences(prefs.copyWith(lastAlertScanAt: now, updatedAt: now));
  }

  /// Create in-app notification for real-time events (reviews, answers, chat).
  Future<void> notifyUser({
    required String userId,
    required String type,
    required String category,
    required String title,
    String body = '',
    String entityType = '',
    String entityId = '',
    String actionRoute = '',
  }) async {
    final prefs = await getOrCreatePreferences(userId);
    if (!isPreferenceEnabled(prefs, type)) return;

    await createNotificationFromDraft(
      userId: userId,
      draft: AlertNotificationDraft(
        type: type,
        category: category,
        title: title,
        body: body,
        entityType: entityType,
        entityId: entityId,
        actionRoute: actionRoute,
      ),
    );
  }
}

class EngagementFirestoreException implements Exception {
  final String message;
  EngagementFirestoreException({required this.message});
  @override
  String toString() => message;
}
