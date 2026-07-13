import '../../../config/router/route_names.dart';
import '../../../core/constants/engagement_constants.dart';
import '../models/engagement_models.dart';

List<AlertNotificationDraft> buildCalendarAlertDrafts({
  required List<AdmissionCalendarEventModel> events,
  required DateTime now,
  int reminderDaysAhead = 14,
}) {
  final drafts = <AlertNotificationDraft>[];
  for (final event in events) {
    if (!event.isActive) continue;
    final target = event.deadlineDate ?? event.eventDate;
    final daysUntil = target.difference(now).inDays;
    if (daysUntil < 0 || daysUntil > reminderDaysAhead) continue;

    final label = EngagementConstants.calendarCategoryLabel(event.category);
    drafts.add(
      AlertNotificationDraft(
        type: EngagementConstants.typeAdmissionReminder,
        category: EngagementConstants.categoryAdmission,
        title: '$label: ${event.title}',
        body: daysUntil == 0
            ? 'Deadline is today for ${event.state}.'
            : 'Due in $daysUntil day${daysUntil == 1 ? '' : 's'} (${event.state}).',
        entityType: 'calendar_event',
        entityId: event.id,
        actionRoute: RouteNames.admissionCalendar,
      ),
    );

    if (daysUntil <= 7 && event.deadlineDate != null) {
      drafts.add(
        AlertNotificationDraft(
          type: EngagementConstants.typeAdmissionDeadline,
          category: EngagementConstants.categoryAdmission,
          title: 'Deadline approaching: ${event.title}',
          body: 'Complete before ${event.deadlineDate!.toLocal().toString().split(' ').first}.',
          entityType: 'calendar_event',
          entityId: '${event.id}_deadline',
          actionRoute: RouteNames.admissionCalendar,
        ),
      );
    }
  }
  return drafts;
}

List<AlertNotificationDraft> buildScholarshipOpenDrafts({
  required List<Map<String, dynamic>> scholarships,
  required DateTime since,
}) {
  final drafts = <AlertNotificationDraft>[];
  for (final s in scholarships) {
    final updatedAt = DateTime.tryParse(s['updatedAt']?.toString() ?? '');
    if (updatedAt == null || updatedAt.isBefore(since)) continue;
    final id = s['id'] as String? ?? '';
    final name = s['name'] as String? ?? 'Scholarship';
    drafts.add(
      AlertNotificationDraft(
        type: EngagementConstants.typeScholarshipOpen,
        category: EngagementConstants.categoryScholarships,
        title: 'Scholarship available: $name',
        body: s['description'] as String? ?? 'A new or updated scholarship is open.',
        entityType: 'scholarship',
        entityId: id,
        actionRoute: RouteNames.admissionScholarships,
      ),
    );
  }
  return drafts;
}

List<AlertNotificationDraft> buildNewEventDrafts({
  required List<Map<String, dynamic>> events,
  required DateTime since,
}) {
  final drafts = <AlertNotificationDraft>[];
  for (final e in events) {
    final createdAt = DateTime.tryParse(e['createdAt']?.toString() ?? '');
    if (createdAt == null || createdAt.isBefore(since)) continue;
    final id = e['id'] as String? ?? '';
    final title = e['title'] as String? ?? 'Campus Event';
    drafts.add(
      AlertNotificationDraft(
        type: EngagementConstants.typeNewEvent,
        category: EngagementConstants.categoryEvents,
        title: 'New event: $title',
        body: e['collegeName'] as String? ?? 'Check out this campus event.',
        entityType: 'campus_event',
        entityId: id,
        actionRoute: RouteNames.studentLifeEventDetailPath(id),
      ),
    );
  }
  return drafts;
}

List<AlertNotificationDraft> buildNewReviewDrafts({
  required List<Map<String, dynamic>> reviews,
  required Set<String> savedCollegeIds,
}) {
  final drafts = <AlertNotificationDraft>[];
  for (final r in reviews) {
    final collegeId = r['collegeId'] as String? ?? '';
    if (!savedCollegeIds.contains(collegeId)) continue;
    final reviewId = r['id'] as String? ?? '';
    final collegeName = r['collegeName'] as String? ?? 'saved college';
    drafts.add(
      AlertNotificationDraft(
        type: EngagementConstants.typeNewReview,
        category: EngagementConstants.categoryReviews,
        title: 'New review on $collegeName',
        body: r['title'] as String? ?? 'A student shared a new review.',
        entityType: 'college',
        entityId: collegeId,
        actionRoute: RouteNames.collegeDetailsPath(collegeId, tab: 'reviews'),
      ),
    );
    if (reviewId.isNotEmpty) {
      // entityId for dedup uses college+type
    }
  }
  return drafts;
}

bool isPreferenceEnabled(
  NotificationPreferencesModel prefs,
  String notificationType,
) {
  if (!prefs.alertsEnabled) return false;
  switch (notificationType) {
    case EngagementConstants.typeNewReview:
      return prefs.newReview;
    case EngagementConstants.typeNewAnswer:
      return prefs.newAnswer;
    case EngagementConstants.typeNewChatMessage:
      return prefs.newChatMessage;
    case EngagementConstants.typeCollegeUpdate:
      return prefs.collegeUpdates;
    case EngagementConstants.typePlacementUpdate:
    case EngagementConstants.typePlacementStatsChange:
      return prefs.placementUpdates || prefs.placementStatsChange;
    case EngagementConstants.typeScholarshipUpdate:
    case EngagementConstants.typeScholarshipOpen:
      return prefs.scholarshipUpdates || prefs.scholarshipOpen;
    case EngagementConstants.typeEventReminder:
      return prefs.eventReminders;
    case EngagementConstants.typeAdmissionReminder:
    case EngagementConstants.typeAdmissionStart:
    case EngagementConstants.typeAdmissionDeadline:
      return prefs.admissionReminders || prefs.admissionDeadline;
    case EngagementConstants.typeFeesChange:
      return prefs.feesChange;
    case EngagementConstants.typeNewEvent:
      return prefs.newEvent;
    case EngagementConstants.typeNewJob:
      return prefs.newJob;
    case EngagementConstants.typeNewInternship:
      return prefs.newInternship;
    case EngagementConstants.typeApplicationUpdate:
      return prefs.applicationUpdate;
    default:
      return true;
  }
}

String dedupeKey(String userId, String type, String entityId) {
  return '${userId}_${type}_$entityId';
}
