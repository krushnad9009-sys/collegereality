import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/admin_session_cache.dart';
import '../models/admin_models.dart';
import '../services/admin_action_logger.dart';
import '../services/admin_analytics_service.dart';
import '../services/admin_user_moderation_service.dart';

final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>((ref) {
  return AdminAnalyticsService();
});

final adminUserModerationServiceProvider = Provider<AdminUserModerationService>((ref) {
  return AdminUserModerationService(
    logger: ref.watch(adminActionLoggerProvider),
  );
});

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final cached = AdminSessionCache.getStats();
  if (cached != null) return cached;

  final service = ref.watch(adminAnalyticsServiceProvider);
  final stats = await service.fetchDashboardStats();
  AdminSessionCache.setStats(stats);
  return stats;
});

final adminAnalyticsDataProvider = FutureProvider<AdminAnalyticsData>((ref) async {
  final cached = AdminSessionCache.getAnalytics();
  if (cached != null) return cached;

  final service = ref.watch(adminAnalyticsServiceProvider);
  final data = await service.fetchAnalyticsData();
  AdminSessionCache.setAnalytics(data);
  return data;
});

final adminOpenReportsProvider = FutureProvider<List<AdminReportSummary>>((ref) async {
  return ref.watch(adminAnalyticsServiceProvider).fetchOpenReports();
});

final adminSystemHealthProvider = FutureProvider<AdminSystemHealth>((ref) async {
  return ref.watch(adminAnalyticsServiceProvider).fetchSystemHealth();
});

final adminUserSearchProvider =
    FutureProvider.family<List<AdminUserSearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return ref.watch(adminUserModerationServiceProvider).searchUsers(query);
});

/// Cursor for one page of [adminUserPageProvider]. `null` means "first page".
class AdminUserPageParams {
  final String? startAfterDocumentId;

  /// null = All, true = Verified only, false = Unverified only.
  final bool? verifiedFilter;

  const AdminUserPageParams({this.startAfterDocumentId, this.verifiedFilter});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserPageParams &&
          startAfterDocumentId == other.startAfterDocumentId &&
          verifiedFilter == other.verifiedFilter;

  @override
  int get hashCode => Object.hash(startAfterDocumentId, verifiedFilter);
}

/// Paginated "all users" listing for the User Management page's default
/// (no search filter) view -- see [AdminUserModerationService.listUsersPage].
final adminUserPageProvider = FutureProvider.family<AdminPageResult<AdminUserSearchResult>,
    AdminUserPageParams>((ref, params) async {
  return ref.watch(adminUserModerationServiceProvider).listUsersPage(
        startAfterDocumentId: params.startAfterDocumentId,
        verifiedFilter: params.verifiedFilter,
      );
});

final adminCollegeStatsExportProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminAnalyticsServiceProvider).fetchCollegeStatsForExport();
});

final adminVerificationExportProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminAnalyticsServiceProvider).fetchVerificationReportExport();
});

final adminUserReportsExportProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminAnalyticsServiceProvider).fetchUserReportExport();
});
