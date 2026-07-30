import '../../../config/router/route_names.dart';

/// Returns true when an FCM `actionRoute` is a safe in-app path.
bool isAllowedFcmActionRoute(String route) {
  final path = route.split('?').first.trim();
  if (path.isEmpty || !path.startsWith('/')) return false;
  if (path.contains('://') || path.contains('..')) return false;
  // Never deep-link into admin surfaces from push payloads.
  if (path == RouteNames.admin || path.startsWith('${RouteNames.admin}/')) {
    return false;
  }

  const allowedExact = <String>{
    RouteNames.home,
    RouteNames.collegeSearch,
    RouteNames.collegeBrowse,
    RouteNames.privacyPolicy,
    RouteNames.termsOfService,
    RouteNames.assistant,
    RouteNames.compare,
    RouteNames.profile,
    RouteNames.displayNameSetup,
    RouteNames.myReviews,
    RouteNames.favorites,
    RouteNames.notifications,
    RouteNames.notificationPreferences,
    RouteNames.admissionCalendar,
    RouteNames.verification,
    RouteNames.guidesDirectory,
    RouteNames.community,
    RouteNames.communityPrivateChats,
    RouteNames.communityAskSeniors,
    RouteNames.communityQa,
    RouteNames.communityDiscussionFeed,
    RouteNames.admissionHub,
    RouteNames.admissionScholarships,
    RouteNames.admissionExams,
    RouteNames.admissionCutoffs,
    RouteNames.admissionPredictor,
    RouteNames.savedPredictions,
    RouteNames.careersHub,
    RouteNames.careersInternships,
    RouteNames.careersJobs,
    RouteNames.careersCompanies,
    RouteNames.careersAlumni,
    RouteNames.careersSaved,
    RouteNames.careersResume,
    RouteNames.careersRecommendations,
    RouteNames.studentLifeHub,
    RouteNames.studentLifeEvents,
    RouteNames.studentLifeClubs,
    RouteNames.studentLifeCompetitions,
    RouteNames.studentLifeCommunities,
    RouteNames.studentLifeSaved,
    RouteNames.rankingHub,
    RouteNames.rankingColleges,
    RouteNames.rankingRecommendations,
    RouteNames.rankingCompare,
    RouteNames.rankingInsights,
    RouteNames.rankingAnalytics,
    RouteNames.howCrScoreWorks,
    RouteNames.requestCollege,
    RouteNames.facultyVerification,
    RouteNames.facultyHub,
  };

  if (allowedExact.contains(path)) return true;

  const allowedPrefixes = <String>[
    '/college-details/',
    '/guides/',
    '/call/',
    '/community/chat/',
    '/student/',
    '/careers/companies/',
    '/careers/alumni/',
    '/student-life/events/',
    '/student-life/clubs/',
    '/student-life/competitions/',
    '/student-life/communities/',
    '/ecosystem/suggest-edit/',
    '/ecosystem/report/',
    '/ecosystem/claim/',
  ];

  return allowedPrefixes.any(path.startsWith);
}