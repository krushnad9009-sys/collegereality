import 'package:college_reality_india/core/constants/engagement_constants.dart';
import 'package:college_reality_india/features/engagement/models/engagement_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 1);

  test('UserNotificationModel JSON round-trip and copyWith', () {
    final n = UserNotificationModel(
      id: 'n1',
      userId: 'u1',
      type: EngagementConstants.typeNewReview,
      category: EngagementConstants.categoryReviews,
      title: 'Hello',
      body: 'Body',
      entityType: 'college',
      entityId: 'c1',
      actionRoute: '/c/c1',
      searchText: 'hello',
      createdAt: now,
    );
    final restored = UserNotificationModel.fromJson(n.toJson(), docId: 'n1');
    expect(restored.title, 'Hello');
    expect(restored.body, 'Body');
    expect(restored.copyWith(isRead: true).isRead, isTrue);
  });

  test('UserNotificationModel fromJson defaults', () {
    final n = UserNotificationModel.fromJson({}, docId: 'x');
    expect(n.id, 'x');
    expect(n.isRead, isFalse);
  });

  test('NotificationPreferencesModel defaults, JSON, copyWith', () {
    final prefs = NotificationPreferencesModel.defaults('u1');
    expect(prefs.alertsEnabled, isTrue);
    final json = prefs.toJson();
    final restored = NotificationPreferencesModel.fromJson(json, docId: 'u1');
    expect(restored.userId, 'u1');
    expect(restored.newReview, isTrue);

    final withScan = NotificationPreferencesModel(
      userId: 'u1',
      lastAlertScanAt: now,
      updatedAt: now,
      newReview: false,
    );
    final round = NotificationPreferencesModel.fromJson(withScan.toJson());
    expect(round.lastAlertScanAt, isNotNull);
    expect(round.copyWith(alertsEnabled: false).alertsEnabled, isFalse);
    expect(round.copyWith(newAnswer: false).newAnswer, isFalse);
    expect(round.copyWith(newChatMessage: false).newChatMessage, isFalse);
    expect(round.copyWith(collegeUpdates: false).collegeUpdates, isFalse);
    expect(round.copyWith(placementUpdates: false).placementUpdates, isFalse);
    expect(round.copyWith(scholarshipUpdates: false).scholarshipUpdates, isFalse);
    expect(round.copyWith(eventReminders: false).eventReminders, isFalse);
    expect(round.copyWith(admissionReminders: false).admissionReminders, isFalse);
    expect(round.copyWith(feesChange: false).feesChange, isFalse);
    expect(round.copyWith(placementStatsChange: false).placementStatsChange, isFalse);
    expect(round.copyWith(scholarshipOpen: false).scholarshipOpen, isFalse);
    expect(round.copyWith(admissionStart: false).admissionStart, isFalse);
    expect(round.copyWith(admissionDeadline: false).admissionDeadline, isFalse);
    expect(round.copyWith(newEvent: false).newEvent, isFalse);
    expect(round.copyWith(newJob: false).newJob, isFalse);
    expect(round.copyWith(newInternship: false).newInternship, isFalse);
    expect(round.copyWith(applicationUpdate: false).applicationUpdate, isFalse);
    expect(round.copyWith(reviewApproved: false).reviewApproved, isFalse);
    expect(round.copyWith(reviewInteraction: false).reviewInteraction, isFalse);
    expect(round.copyWith(verificationUpdates: false).verificationUpdates, isFalse);
    expect(round.copyWith(communityUpdates: false).communityUpdates, isFalse);
    expect(round.copyWith(adminAnnouncements: false).adminAnnouncements, isFalse);
  });

  test('AdmissionCalendarEventModel JSON and getters', () {
    final upcoming = AdmissionCalendarEventModel(
      id: 'e1',
      title: 'CAP',
      category: EngagementConstants.calendarCapRound,
      state: 'MH',
      eventDate: DateTime.now().add(const Duration(days: 3)),
      deadlineDate: DateTime.now().add(const Duration(days: 5)),
      updatedAt: now,
    );
    expect(upcoming.isUpcoming, isTrue);
    expect(upcoming.isDeadlineSoon, isTrue);
    final restored = AdmissionCalendarEventModel.fromJson(upcoming.toJson(), docId: 'e1');
    expect(restored.title, 'CAP');
    expect(restored.deadlineDate, isNotNull);

    final past = AdmissionCalendarEventModel(
      id: 'e2',
      title: 'Old',
      category: EngagementConstants.calendarExamDate,
      eventDate: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: now,
    );
    expect(past.isUpcoming, isFalse);
    expect(AdmissionCalendarEventModel.fromJson({}).id, '');
  });

  test('AlertNotificationDraft holds fields', () {
    const d = AlertNotificationDraft(
      type: 't',
      category: 'c',
      title: 'Title',
      body: 'b',
      entityType: 'e',
      entityId: '1',
      actionRoute: '/a',
    );
    expect(d.title, 'Title');
  });
}