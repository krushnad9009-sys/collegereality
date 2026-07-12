class RouteNames {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String collegeSearch = '/college-search';
  static const String collegeDetails = '/college-details/:id';
  static const String writeReview = '/college-details/:id/write-review';
  static const String profile = '/profile';
  static const String myReviews = '/my-reviews';
  static const String favorites = '/favorites';
  static const String admin = '/admin';
  static const String adminColleges = '/admin/colleges';
  static const String adminReviews = '/admin/reviews';
  static const String adminUsers = '/admin/users';
  static const String adminCommunication = '/admin/communication';
  static const String adminVerification = '/admin/verification';
  static const String verification = '/verification';
  static const String guidesDirectory = '/guides';
  static const String guideProfile = '/guides/:uid';
  static const String activeCall = '/call/:sessionId';

  static String collegeDetailsPath(String id, {String? tab}) {
    final path = '/college-details/$id';
    if (tab == null || tab.isEmpty) return path;
    return '$path?tab=$tab';
  }
  static String writeReviewPath(String collegeId) =>
      '/college-details/$collegeId/write-review';
  static String guideProfilePath(String uid) => '/guides/$uid';
  static String activeCallPath(String sessionId) => '/call/$sessionId';
}
