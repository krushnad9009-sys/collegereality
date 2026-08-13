class SuperAdminRouteNames {
  static const String login = '/panel/login';
  static const String accessDenied = '/panel/access-denied';
  static const String dashboard = '/panel/dashboard';
  static const String users = '/panel/users';
  static const String roles = '/panel/roles';
  static const String colleges = '/panel/colleges';
  static const String collegeNew = '/panel/colleges/new';
  static const String collegeEdit = '/panel/colleges/:id/edit';
  static const String mergeColleges = '/panel/merge-colleges';
  static const String crScore = '/panel/cr-score';
  static const String moderation = '/panel/moderation';
  static const String reviews = '/panel/reviews';
  static const String community = '/panel/community';
  static const String reports = '/panel/reports';
  static const String questions = '/panel/questions';
  static const String verification = '/panel/verification';
  static const String notifications = '/panel/notifications';
  static const String analytics = '/panel/analytics';
  static const String settings = '/panel/settings';
  static const String export = '/panel/export';
  static const String ecosystem = '/panel/ecosystem';
  static const String studentLife = '/panel/student-life';
  static const String ads = '/panel/ads';
  static const String auditLogs = '/panel/audit-logs';
  static const String consultations = '/panel/consultations';
  static const String consultationRevenue = '/panel/consultation-revenue';

  static String collegeEditPath(String id) => '/panel/colleges/$id/edit';
}
