class RouteNames {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String collegeSearch = '/college-search';
  static const String assistant = '/assistant';
  static const String compare = '/compare';
  static const String collegeDetails = '/college-details/:id';
  static const String writeReview = '/college-details/:id/write-review';
  static const String submitPlacement = '/college-details/:id/submit-placement';
  static const String profile = '/profile';
  static const String myReviews = '/my-reviews';
  static const String favorites = '/favorites';
  static const String admin = '/admin';
  static const String adminColleges = '/admin/colleges';
  static const String adminCollegeNew = '/admin/colleges/new';
  static const String adminCollegeEdit = '/admin/colleges/:id/edit';
  static const String adminReviews = '/admin/reviews';
  static const String adminPlacements = '/admin/placements';
  static const String adminUsers = '/admin/users';
  static const String adminCommunication = '/admin/communication';
  static const String adminVerification = '/admin/verification';
  static const String verification = '/verification';
  static const String guidesDirectory = '/guides';
  static const String guideProfile = '/guides/:uid';
  static const String activeCall = '/call/:sessionId';
  static const String community = '/community';
  static const String communityPrivateChats = '/community/private-chats';
  static const String communityChat = '/community/chat/:id';
  static const String communityAskSeniors = '/community/ask-seniors';
  static const String communityQa = '/community/qa';
  static const String adminCommunity = '/admin/community';
  static const String adminQuestions = '/admin/questions';
  static const String admissionHub = '/admission';
  static const String admissionScholarships = '/admission/scholarships';
  static const String admissionExams = '/admission/exams';
  static const String admissionCutoffs = '/admission/cutoffs';
  static const String admissionPredictor = '/admission/predictor';
  static const String savedPredictions = '/admission/predictions';
  static const String studentProfile = '/student/:uid';
  static const String collegeQuestion = '/college-details/:id/questions/:questionId';
  static const String careersHub = '/careers';
  static const String careersInternships = '/careers/internships';
  static const String careersJobs = '/careers/jobs';
  static const String careersCompanies = '/careers/companies';
  static const String careersCompanyDetail = '/careers/companies/:id';
  static const String careersAlumni = '/careers/alumni';
  static const String careersAlumniDetail = '/careers/alumni/:id';
  static const String careersSaved = '/careers/saved';
  static const String studentLifeHub = '/student-life';
  static const String studentLifeEvents = '/student-life/events';
  static const String studentLifeEventDetail = '/student-life/events/:id';
  static const String studentLifeClubs = '/student-life/clubs';
  static const String studentLifeClubDetail = '/student-life/clubs/:id';
  static const String studentLifeCompetitions = '/student-life/competitions';
  static const String studentLifeCompetitionDetail = '/student-life/competitions/:id';
  static const String studentLifeCommunities = '/student-life/communities';
  static const String studentLifeCommunityBoard = '/student-life/communities/:id';
  static const String studentLifeSaved = '/student-life/saved';
  static const String adminStudentLife = '/admin/student-life';

  static String collegeDetailsPath(String id, {String? tab}) {
    final path = '/college-details/$id';
    if (tab == null || tab.isEmpty) return path;
    return '$path?tab=$tab';
  }
  static String writeReviewPath(String collegeId) =>
      '/college-details/$collegeId/write-review';
  static String submitPlacementPath(String collegeId, String collegeName) =>
      '/college-details/$collegeId/submit-placement?name=${Uri.encodeComponent(collegeName)}';
  static String guideProfilePath(String uid) => '/guides/$uid';
  static String activeCallPath(String sessionId) => '/call/$sessionId';
  static String communityChatPath(String id) => '/community/chat/$id';
  static String studentProfilePath(String uid) => '/student/$uid';
  static String adminCollegeEditPath(String id) => '/admin/colleges/$id/edit';
  static String collegeQuestionPath(String collegeId, String questionId) =>
      '/college-details/$collegeId/questions/$questionId';
  static String careersCompanyDetailPath(String companyId) =>
      '/careers/companies/$companyId';
  static String careersAlumniDetailPath(String alumniId) =>
      '/careers/alumni/$alumniId';
  static String studentLifeEventDetailPath(String eventId) =>
      '/student-life/events/$eventId';
  static String studentLifeClubDetailPath(String clubId) =>
      '/student-life/clubs/$clubId';
  static String studentLifeCompetitionDetailPath(String competitionId) =>
      '/student-life/competitions/$competitionId';
  static String studentLifeCommunityBoardPath(String communityId) =>
      '/student-life/communities/$communityId';

  static String assistantPath({
    String? query,
    String? collegeId,
    String? collegeName,
  }) {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (collegeId != null && collegeId.isNotEmpty) {
      params['collegeId'] = collegeId;
    }
    if (collegeName != null && collegeName.isNotEmpty) {
      params['collegeName'] = collegeName;
    }
    if (params.isEmpty) return assistant;
    return Uri(path: assistant, queryParameters: params).toString();
  }

  static String comparePath({required List<String> ids}) {
    return Uri(
      path: compare,
      queryParameters: {'ids': ids.join(',')},
    ).toString();
  }
}
