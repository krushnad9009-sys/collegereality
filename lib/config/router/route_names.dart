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

  static String collegeDetailsPath(String id) => '/college-details/$id';
  static String writeReviewPath(String collegeId) =>
      '/college-details/$collegeId/write-review';
}
