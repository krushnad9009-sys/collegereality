import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/engagement_constants.dart';
import 'package:college_reality_india/features/engagement/models/engagement_models.dart';
import 'package:college_reality_india/features/engagement/utils/alert_scanner.dart';
import 'package:college_reality_india/features/engagement/utils/engagement_filter_utils.dart';

void main() {
  group('EngagementFilterUtils', () {
    UserNotificationModel sampleNotification({
      required String id,
      required String title,
      String category = EngagementConstants.categoryAdmission,
      bool isRead = false,
    }) {
      return UserNotificationModel(
        id: id,
        userId: 'user1',
        type: EngagementConstants.typeAdmissionReminder,
        category: category,
        title: title,
        body: 'Test body',
        searchText: title.toLowerCase(),
        isRead: isRead,
        createdAt: DateTime(2026, 7, 10),
      );
    }

    test('filterNotifications applies search and unread filters', () {
      final items = [
        sampleNotification(id: '1', title: 'CAP Round 1', isRead: false),
        sampleNotification(id: '2', title: 'JEE Result', isRead: true),
      ];

      final unread = filterNotifications(
        items: items,
        searchQuery: '',
        unreadOnly: true,
      );
      expect(unread.length, 1);
      expect(unread.first.title, 'CAP Round 1');

      final searched = filterNotifications(
        items: items,
        searchQuery: 'jee',
        unreadOnly: false,
      );
      expect(searched.length, 1);
      expect(searched.first.title, 'JEE Result');
    });

    test('filterCalendarEvents filters by category and upcoming', () {
      final now = DateTime(2026, 7, 13);
      final events = [
        AdmissionCalendarEventModel(
          id: '1',
          title: 'CAP Round 1',
          category: EngagementConstants.calendarCapRound,
          state: 'Maharashtra',
          eventDate: now.add(const Duration(days: 5)),
          updatedAt: now,
        ),
        AdmissionCalendarEventModel(
          id: '2',
          title: 'Past Event',
          category: EngagementConstants.calendarCounselling,
          state: 'Maharashtra',
          eventDate: now.subtract(const Duration(days: 3)),
          updatedAt: now,
        ),
      ];

      final upcoming = filterCalendarEvents(
        items: events,
        searchQuery: '',
        category: null,
        upcomingOnly: true,
      );
      expect(upcoming.length, 1);
      expect(upcoming.first.title, 'CAP Round 1');

      final capOnly = filterCalendarEvents(
        items: events,
        searchQuery: '',
        category: EngagementConstants.calendarCapRound,
        upcomingOnly: false,
      );
      expect(capOnly.length, 1);
    });
  });

  group('AlertScanner', () {
    test('buildCalendarAlertDrafts creates reminders for upcoming deadlines', () {
      final now = DateTime(2026, 7, 13);
      final events = [
        AdmissionCalendarEventModel(
          id: 'cal_1',
          title: 'Fee Payment',
          category: EngagementConstants.calendarFeePayment,
          state: 'Maharashtra',
          eventDate: now.add(const Duration(days: 2)),
          deadlineDate: now.add(const Duration(days: 5)),
          updatedAt: now,
        ),
      ];

      final drafts = buildCalendarAlertDrafts(events: events, now: now);
      expect(drafts, isNotEmpty);
      expect(drafts.first.type, EngagementConstants.typeAdmissionReminder);
    });

    test('isPreferenceEnabled respects master toggle', () {
      final prefs = NotificationPreferencesModel.defaults('u1').copyWith(
        alertsEnabled: false,
      );
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeNewReview),
        isFalse,
      );
    });

    test('isPreferenceEnabled maps verification and admin types', () {
      final prefs = NotificationPreferencesModel.defaults('u1');
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeAdminAnnouncement),
        isTrue,
      );
      expect(
        isPreferenceEnabled(prefs, EngagementConstants.typeReviewApproved),
        isTrue,
      );
    });

    test('dedupeKey is stable', () {
      expect(
        dedupeKey('u1', EngagementConstants.typeNewReview, 'col_1'),
        'u1_new_review_col_1',
      );
    });
  });
}
