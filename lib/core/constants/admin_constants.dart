class AdminConstants {
  AdminConstants._();

  static const String metaAdminStatsDoc = 'admin_dashboard_stats';
  static const String metaSystemHealthDoc = 'admin_system_health';

  static const int defaultPageSize = 24;
  static const int maxSearchUsers = 50;
  static const int analyticsSampleLimit = 200;
  static const Duration statsCacheTtl = Duration(minutes: 10);

  static const String accountStatusActive = 'active';
  static const String accountStatusSuspended = 'suspended';
  static const String accountStatusBanned = 'banned';

  static const String reportStatusOpen = 'open';
  static const String reportStatusReviewed = 'reviewed';
  static const String reportStatusActionTaken = 'action_taken';

  static const String exportTypeAnalytics = 'analytics';
  static const String exportTypeReports = 'reports';
  static const String exportTypeColleges = 'colleges';
}
