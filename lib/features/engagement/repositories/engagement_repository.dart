import '../models/engagement_models.dart';
import '../services/firestore_engagement_service.dart';

abstract class EngagementRepository {
  Future<void> ensureSeeded();
  Stream<List<UserNotificationModel>> watchUserNotifications(String userId);
  Stream<int> watchUnreadCount(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<NotificationPreferencesModel> getOrCreatePreferences(String userId);
  Stream<NotificationPreferencesModel> watchPreferences(String userId);
  Future<void> updatePreferences(NotificationPreferencesModel prefs);
  Stream<List<AdmissionCalendarEventModel>> watchCalendarEvents();
  Future<void> runPersonalizedAlertScan(String userId);
  Stream<Set<String>> watchFavoriteCollegeIds(String userId);
  Future<void> toggleFavoriteCollege(String userId, String collegeId);
  Future<void> saveEntranceExam(String userId, String examId);
  Future<void> unsaveEntranceExam(String userId, String examId);
  Stream<Set<String>> watchSavedExamIds(String userId);
  Future<void> saveQuestion(String userId, String questionId, {String? collegeId});
  Future<void> unsaveQuestion(String userId, String questionId);
  Stream<Set<String>> watchSavedQuestionIds(String userId);
  Future<void> notifyUser({
    required String userId,
    required String type,
    required String category,
    required String title,
    String body,
    String entityType,
    String entityId,
    String actionRoute,
  });
}

class EngagementRepositoryImpl implements EngagementRepository {
  final FirestoreEngagementService _service;

  EngagementRepositoryImpl(this._service);

  @override
  Future<void> ensureSeeded() => _service.ensureSeeded();

  @override
  Stream<List<UserNotificationModel>> watchUserNotifications(String userId) =>
      _service.watchUserNotifications(userId);

  @override
  Stream<int> watchUnreadCount(String userId) => _service.watchUnreadCount(userId);

  @override
  Future<void> markAsRead(String notificationId) =>
      _service.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead(String userId) => _service.markAllAsRead(userId);

  @override
  Future<void> deleteNotification(String notificationId) =>
      _service.deleteNotification(notificationId);

  @override
  Future<NotificationPreferencesModel> getOrCreatePreferences(String userId) =>
      _service.getOrCreatePreferences(userId);

  @override
  Stream<NotificationPreferencesModel> watchPreferences(String userId) =>
      _service.watchPreferences(userId);

  @override
  Future<void> updatePreferences(NotificationPreferencesModel prefs) =>
      _service.updatePreferences(prefs);

  @override
  Stream<List<AdmissionCalendarEventModel>> watchCalendarEvents() =>
      _service.watchCalendarEvents();

  @override
  Future<void> runPersonalizedAlertScan(String userId) =>
      _service.runPersonalizedAlertScan(userId);

  @override
  Stream<Set<String>> watchFavoriteCollegeIds(String userId) =>
      _service.watchFavoriteCollegeIds(userId);

  @override
  Future<void> toggleFavoriteCollege(String userId, String collegeId) =>
      _service.toggleFavoriteCollege(userId, collegeId);

  @override
  Future<void> saveEntranceExam(String userId, String examId) =>
      _service.saveEntranceExam(userId, examId);

  @override
  Future<void> unsaveEntranceExam(String userId, String examId) =>
      _service.unsaveEntranceExam(userId, examId);

  @override
  Stream<Set<String>> watchSavedExamIds(String userId) =>
      _service.watchSavedExamIds(userId);

  @override
  Future<void> saveQuestion(String userId, String questionId, {String? collegeId}) =>
      _service.saveQuestion(userId, questionId, collegeId: collegeId);

  @override
  Future<void> unsaveQuestion(String userId, String questionId) =>
      _service.unsaveQuestion(userId, questionId);

  @override
  Stream<Set<String>> watchSavedQuestionIds(String userId) =>
      _service.watchSavedQuestionIds(userId);

  @override
  Future<void> notifyUser({
    required String userId,
    required String type,
    required String category,
    required String title,
    String body = '',
    String entityType = '',
    String entityId = '',
    String actionRoute = '',
  }) =>
      _service.notifyUser(
        userId: userId,
        type: type,
        category: category,
        title: title,
        body: body,
        entityType: entityType,
        entityId: entityId,
        actionRoute: actionRoute,
      );
}
