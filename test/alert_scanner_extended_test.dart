import 'package:college_reality_india/core/constants/engagement_constants.dart';
import 'package:college_reality_india/features/engagement/models/engagement_models.dart';
import 'package:college_reality_india/features/engagement/utils/alert_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 13);

  test('buildScholarshipOpenDrafts / events / reviews', () {
    final scholarships = buildScholarshipOpenDrafts(
      scholarships: [
        {
          'id': 's1',
          'name': 'Merit',
          'description': 'Desc',
          'updatedAt': now.toIso8601String(),
        },
        {
          'id': 's2',
          'name': 'Old',
          'updatedAt': now.subtract(const Duration(days: 30)).toIso8601String(),
        },
        {'id': 's3', 'name': 'Bad'},
      ],
      since: now.subtract(const Duration(days: 7)),
    );
    expect(scholarships.length, 1);
    expect(scholarships.first.title, contains('Merit'));

    final events = buildNewEventDrafts(
      events: [
        {
          'id': 'e1',
          'title': 'Fest',
          'collegeName': 'COEP',
          'createdAt': now.toIso8601String(),
        },
        {'id': 'e2', 'title': 'Skip'},
      ],
      since: now.subtract(const Duration(days: 2)),
    );
    expect(events.length, 1);

    final reviews = buildNewReviewDrafts(
      reviews: [
        {
          'id': 'r1',
          'collegeId': 'c1',
          'collegeName': 'COEP',
          'title': 'Great',
        },
        {'id': 'r2', 'collegeId': 'c2', 'collegeName': 'Other'},
      ],
      savedCollegeIds: {'c1'},
    );
    expect(reviews.length, 1);
    expect(reviews.first.title, contains('COEP'));
  });

  test('buildCalendarAlertDrafts deadline branch and inactive skip', () {
    final drafts = buildCalendarAlertDrafts(
      events: [
        AdmissionCalendarEventModel(
          id: 'cal1',
          title: 'Fee',
          category: EngagementConstants.calendarFeePayment,
          state: 'MH',
          eventDate: now.add(const Duration(days: 2)),
          deadlineDate: now.add(const Duration(days: 2)),
          updatedAt: now,
        ),
        AdmissionCalendarEventModel(
          id: 'cal2',
          title: 'Inactive',
          category: EngagementConstants.calendarCapRound,
          eventDate: now.add(const Duration(days: 1)),
          isActive: false,
          updatedAt: now,
        ),
        AdmissionCalendarEventModel(
          id: 'cal3',
          title: 'Far',
          category: EngagementConstants.calendarExamDate,
          eventDate: now.add(const Duration(days: 40)),
          updatedAt: now,
        ),
        AdmissionCalendarEventModel(
          id: 'cal4',
          title: 'Today',
          category: EngagementConstants.calendarResultDate,
          state: 'MH',
          eventDate: now,
          updatedAt: now,
        ),
      ],
      now: now,
    );
    expect(drafts.any((d) => d.title.contains('Fee')), isTrue);
    expect(drafts.any((d) => d.title.contains('Deadline approaching')), isTrue);
    expect(drafts.any((d) => d.title.contains('Today')), isTrue);
    expect(drafts.any((d) => d.title.contains('Inactive')), isFalse);
  });

  test('isPreferenceEnabled covers preference matrix', () {
    final prefs = NotificationPreferencesModel(
      userId: 'u1',
      updatedAt: now,
      alertsEnabled: true,
    );
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeNewReview), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeNewAnswer), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeNewChatMessage), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeCollegeUpdate), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typePlacementUpdate), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typePlacementStatsChange), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeScholarshipUpdate), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeScholarshipOpen), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeEventReminder), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeAdmissionReminder), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeAdmissionStart), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeAdmissionDeadline), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeFeesChange), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeNewEvent), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeNewJob), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeNewInternship), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeApplicationUpdate), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeVerificationUpdate), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeReviewApproved), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeReviewComment), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeCommunityPost), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeCommunityComment), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeCommunityReply), isTrue);
    expect(isPreferenceEnabled(prefs, EngagementConstants.typeAdminAnnouncement), isTrue);
    expect(isPreferenceEnabled(prefs, 'unknown_type'), isTrue);

    final off = prefs.copyWith(alertsEnabled: false);
    expect(isPreferenceEnabled(off, EngagementConstants.typeNewReview), isFalse);
    expect(dedupeKey('u1', 't', 'e'), 'u1_t_e');
  });
}