import '../../../core/constants/engagement_constants.dart';
import '../models/engagement_models.dart';

String buildEngagementSearchText(List<String> parts) {
  return parts
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .toLowerCase();
}

List<UserNotificationModel> filterNotifications({
  required List<UserNotificationModel> items,
  required String searchQuery,
  String? category,
  bool unreadOnly = false,
}) {
  final query = searchQuery.trim().toLowerCase();
  return items.where((n) {
    if (unreadOnly && n.isRead) return false;
    if (category != null && category.isNotEmpty && n.category != category) {
      return false;
    }
    if (query.isEmpty) return true;
    return n.searchText.contains(query) ||
        n.title.toLowerCase().contains(query) ||
        n.body.toLowerCase().contains(query);
  }).toList();
}

List<AdmissionCalendarEventModel> filterCalendarEvents({
  required List<AdmissionCalendarEventModel> items,
  required String searchQuery,
  String? category,
  String? state,
  bool upcomingOnly = false,
}) {
  final query = searchQuery.trim().toLowerCase();
  return items.where((e) {
    if (!e.isActive) return false;
    if (upcomingOnly && !e.isUpcoming) return false;
    if (category != null && category.isNotEmpty && e.category != category) {
      return false;
    }
    if (state != null && state.isNotEmpty && e.state != state) return false;
    if (query.isEmpty) return true;
    return e.searchText.contains(query) ||
        e.title.toLowerCase().contains(query) ||
        e.state.toLowerCase().contains(query);
  }).toList();
}

String notificationCategoryIcon(String category) {
  switch (category) {
    case EngagementConstants.categoryReviews:
      return 'rate_review';
    case EngagementConstants.categoryQuestions:
      return 'help_outline';
    case EngagementConstants.categoryChat:
      return 'chat';
    case EngagementConstants.categoryColleges:
      return 'school';
    case EngagementConstants.categoryPlacements:
      return 'work';
    case EngagementConstants.categoryScholarships:
      return 'card_giftcard';
    case EngagementConstants.categoryEvents:
      return 'event';
    case EngagementConstants.categoryAdmission:
      return 'calendar_today';
    default:
      return 'notifications';
  }
}
