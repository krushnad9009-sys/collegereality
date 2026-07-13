import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/colleges/screens/college_search_screen.dart';
import '../../features/colleges/screens/college_detail_screen.dart';
import '../../features/assistant/screens/ai_assistant_screen.dart';
import '../../features/compare/screens/college_compare_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../../features/reviews/screens/my_reviews_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_college_edit_screen.dart';
import '../../features/admin/screens/admin_colleges_screen.dart';
import '../../features/admin/screens/admin_reviews_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/admin/screens/admin_verification_screen.dart';
import '../../features/profile/screens/premium_student_profile_screen.dart';
import '../../features/verification/screens/verification_screen.dart';
import '../../features/community/screens/community_hub_screen.dart';
import '../../features/community/screens/private_chats_screen.dart';
import '../../features/community/screens/chat_screen.dart';
import '../../features/community/screens/ask_seniors_screen.dart';
import '../../features/community/screens/qa_board_screen.dart';
import '../../features/social/screens/college_discussion_feed_screen.dart';
import '../../features/ranking/screens/ranking_hub_screen.dart';
import '../../features/ranking/screens/college_rankings_screen.dart';
import '../../features/ranking/screens/smart_recommendations_screen.dart';
import '../../features/ranking/screens/compare_recommendations_screen.dart';
import '../../features/ranking/screens/college_insights_screen.dart';
import '../../features/ranking/screens/college_analytics_screen.dart';
import '../../features/placements/screens/submit_placement_screen.dart';
import '../../features/questions/screens/question_detail_screen.dart';
import '../../features/admission/screens/admission_hub_screen.dart';
import '../../features/admission/screens/scholarships_screen.dart';
import '../../features/admission/screens/entrance_exams_screen.dart';
import '../../features/admission/screens/cutoffs_screen.dart';
import '../../features/admission/screens/admission_predictor_screen.dart';
import '../../features/admission/screens/saved_predictions_screen.dart';
import '../../features/careers/screens/careers_hub_screen.dart';
import '../../features/careers/screens/internships_screen.dart';
import '../../features/careers/screens/jobs_screen.dart';
import '../../features/careers/screens/companies_screen.dart';
import '../../features/careers/screens/alumni_screen.dart';
import '../../features/careers/screens/saved_careers_screen.dart';
import '../../features/careers/screens/resume_hub_screen.dart';
import '../../features/careers/screens/career_recommendations_screen.dart';
import '../../features/careers/screens/company_dashboard_screen.dart';
import '../../features/careers/screens/post_internship_screen.dart';
import '../../features/careers/screens/post_job_screen.dart';
import '../../features/careers/screens/manage_applicants_screen.dart';
import '../../features/student_life/screens/student_life_hub_screen.dart';
import '../../features/student_life/screens/events_screen.dart';
import '../../features/student_life/screens/clubs_screen.dart';
import '../../features/student_life/screens/competitions_screen.dart';
import '../../features/student_life/screens/student_communities_screen.dart';
import '../../features/student_life/screens/saved_events_screen.dart';
import '../../features/engagement/screens/notifications_center_screen.dart';
import '../../features/engagement/screens/bookmarks_hub_screen.dart';
import '../../features/engagement/screens/admission_calendar_screen.dart';
import '../../features/engagement/screens/notification_preferences_screen.dart';
import '../../features/admin/screens/admin_placements_screen.dart';
import '../../features/admin/screens/admin_community_screen.dart';
import '../../features/admin/screens/admin_communication_screen.dart';
import '../../features/admin/screens/admin_questions_screen.dart';
import '../../features/admin/screens/admin_student_life_screen.dart';
import '../../features/communication/screens/guides_directory_screen.dart';
import '../../features/communication/screens/guide_public_profile_screen.dart';
import '../../features/communication/screens/active_call_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = FirebaseAuth.instance;

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isLoggedIn = firebaseAuth.currentUser != null;
      final path = state.uri.path;
      final isPublicRoute = path == RouteNames.splash ||
          path == RouteNames.onboarding ||
          path == RouteNames.login ||
          path == RouteNames.signup ||
          path == RouteNames.forgotPassword;

      if (!isLoggedIn && !isPublicRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn &&
          (path == RouteNames.login ||
              path == RouteNames.signup ||
              path == RouteNames.onboarding ||
              path == RouteNames.forgotPassword)) {
        return RouteNames.home;
      }

      final isAdminRoute = path.startsWith('/admin');
      if (isAdminRoute && isLoggedIn) {
        final isAdmin = await ref.read(isAdminProvider.future);
        if (!isAdmin) return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.verification,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.studentProfile,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return PremiumStudentProfileScreen(studentUid: uid);
        },
      ),
      GoRoute(
        path: RouteNames.myReviews,
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (context, state) => const BookmarksHubScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsCenterScreen(),
      ),
      GoRoute(
        path: RouteNames.notificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: RouteNames.compare,
        builder: (context, state) {
          final idsParam = state.uri.queryParameters['ids'] ?? '';
          final ids = idsParam
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          return CollegeCompareScreen(collegeIds: ids);
        },
      ),
      GoRoute(
        path: RouteNames.assistant,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          final collegeId = state.uri.queryParameters['collegeId'];
          final collegeName = state.uri.queryParameters['collegeName'];
          return AiAssistantScreen(
            initialQuery: query,
            anchorCollegeId: collegeId,
            anchorCollegeName: collegeName,
          );
        },
      ),
      GoRoute(
        path: RouteNames.rankingHub,
        builder: (context, state) => const RankingHubScreen(),
      ),
      GoRoute(
        path: RouteNames.rankingColleges,
        builder: (context, state) => const CollegeRankingsScreen(),
      ),
      GoRoute(
        path: RouteNames.rankingRecommendations,
        builder: (context, state) => const SmartRecommendationsScreen(),
      ),
      GoRoute(
        path: RouteNames.rankingCompare,
        builder: (context, state) => const CompareRecommendationsScreen(),
      ),
      GoRoute(
        path: RouteNames.rankingInsights,
        builder: (context, state) => const CollegeInsightsScreen(),
      ),
      GoRoute(
        path: RouteNames.rankingAnalytics,
        builder: (context, state) => const CollegeAnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.collegeSearch,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          final city = state.uri.queryParameters['city'];
          final stateParam = state.uri.queryParameters['state'];
          final course = state.uri.queryParameters['course'];
          return CollegeSearchScreen(
            initialQuery: query,
            initialCity: city,
            initialState: stateParam,
            initialCourse: course,
          );
        },
      ),
      GoRoute(
        path: RouteNames.collegeDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final tab = state.uri.queryParameters['tab'];
          return CollegeDetailScreen(collegeId: id, initialTab: tab);
        },
      ),
      GoRoute(
        path: RouteNames.writeReview,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final collegeName = state.uri.queryParameters['name'] ?? 'College';
          return WriteReviewScreen(collegeId: id, collegeName: collegeName);
        },
      ),
      GoRoute(
        path: RouteNames.submitPlacement,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final collegeName = state.uri.queryParameters['name'] ?? 'College';
          return SubmitPlacementScreen(
            collegeId: id,
            collegeName: collegeName,
          );
        },
      ),
      GoRoute(
        path: RouteNames.admissionHub,
        builder: (context, state) => const AdmissionHubScreen(),
      ),
      GoRoute(
        path: RouteNames.admissionScholarships,
        builder: (context, state) => const ScholarshipsScreen(),
      ),
      GoRoute(
        path: RouteNames.admissionExams,
        builder: (context, state) => const EntranceExamsScreen(),
      ),
      GoRoute(
        path: RouteNames.admissionCutoffs,
        builder: (context, state) => const CutoffsScreen(),
      ),
      GoRoute(
        path: RouteNames.admissionPredictor,
        builder: (context, state) => const AdmissionPredictorScreen(),
      ),
      GoRoute(
        path: RouteNames.savedPredictions,
        builder: (context, state) => const SavedPredictionsScreen(),
      ),
      GoRoute(
        path: RouteNames.admissionCalendar,
        builder: (context, state) => const AdmissionCalendarScreen(),
      ),
      GoRoute(
        path: RouteNames.careersHub,
        builder: (context, state) => const CareersHubScreen(),
      ),
      GoRoute(
        path: RouteNames.careersInternships,
        builder: (context, state) => const InternshipsScreen(),
      ),
      GoRoute(
        path: RouteNames.careersJobs,
        builder: (context, state) => const JobsScreen(),
      ),
      GoRoute(
        path: RouteNames.careersCompanies,
        builder: (context, state) => const CompaniesScreen(),
      ),
      GoRoute(
        path: RouteNames.careersCompanyDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompanyDetailScreen(companyId: id);
        },
      ),
      GoRoute(
        path: RouteNames.careersAlumni,
        builder: (context, state) => const AlumniDirectoryScreen(),
      ),
      GoRoute(
        path: RouteNames.careersAlumniDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AlumniProfileScreen(alumniId: id);
        },
      ),
      GoRoute(
        path: RouteNames.careersSaved,
        builder: (context, state) => const SavedCareersScreen(),
      ),
      GoRoute(
        path: RouteNames.careersResume,
        builder: (context, state) => const ResumeHubScreen(),
      ),
      GoRoute(
        path: RouteNames.careersRecommendations,
        builder: (context, state) => const CareerRecommendationsScreen(),
      ),
      GoRoute(
        path: RouteNames.careersCompanyDashboard,
        builder: (context, state) => const CompanyDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.careersPostInternship,
        builder: (context, state) => const PostInternshipScreen(),
      ),
      GoRoute(
        path: RouteNames.careersPostJob,
        builder: (context, state) => const PostJobScreen(),
      ),
      GoRoute(
        path: RouteNames.careersManageApplicants,
        builder: (context, state) => const ManageApplicantsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentLifeHub,
        builder: (context, state) => const StudentLifeHubScreen(),
      ),
      GoRoute(
        path: RouteNames.studentLifeEvents,
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentLifeEventDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: RouteNames.studentLifeClubs,
        builder: (context, state) => const ClubsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentLifeClubDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClubDetailScreen(clubId: id);
        },
      ),
      GoRoute(
        path: RouteNames.studentLifeCompetitions,
        builder: (context, state) => const CompetitionsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentLifeCompetitionDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompetitionDetailScreen(competitionId: id);
        },
      ),
      GoRoute(
        path: RouteNames.studentLifeCommunities,
        builder: (context, state) => const StudentCommunitiesScreen(),
      ),
      GoRoute(
        path: RouteNames.studentLifeCommunityBoard,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CommunityBoardScreen(communityId: id);
        },
      ),
      GoRoute(
        path: RouteNames.studentLifeSaved,
        builder: (context, state) => const SavedEventsScreen(),
      ),
      GoRoute(
        path: RouteNames.collegeQuestion,
        builder: (context, state) {
          final collegeId = state.pathParameters['id']!;
          final questionId = state.pathParameters['questionId']!;
          return QuestionDetailScreen(
            collegeId: collegeId,
            questionId: questionId,
          );
        },
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminColleges,
        builder: (context, state) => const AdminCollegesScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCollegeNew,
        builder: (context, state) => const AdminCollegeEditScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCollegeEdit,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminCollegeEditScreen(collegeId: id);
        },
      ),
      GoRoute(
        path: RouteNames.adminReviews,
        builder: (context, state) => const AdminReviewsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminPlacements,
        builder: (context, state) => const AdminPlacementsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCommunication,
        builder: (context, state) => const AdminCommunicationScreen(),
      ),
      GoRoute(
        path: RouteNames.adminVerification,
        builder: (context, state) => const AdminVerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCommunity,
        builder: (context, state) => const AdminCommunityScreen(),
      ),
      GoRoute(
        path: RouteNames.adminQuestions,
        builder: (context, state) => const AdminQuestionsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminStudentLife,
        builder: (context, state) => const AdminStudentLifeScreen(),
      ),
      GoRoute(
        path: RouteNames.community,
        builder: (context, state) => const CommunityHubScreen(),
      ),
      GoRoute(
        path: RouteNames.communityPrivateChats,
        builder: (context, state) => const PrivateChatsScreen(),
      ),
      GoRoute(
        path: RouteNames.communityAskSeniors,
        builder: (context, state) => const AskSeniorsScreen(),
      ),
      GoRoute(
        path: RouteNames.communityQa,
        builder: (context, state) => const QaBoardScreen(),
      ),
      GoRoute(
        path: RouteNames.communityDiscussionFeed,
        builder: (context, state) => const CollegeDiscussionFeedScreen(),
      ),
      GoRoute(
        path: RouteNames.communityChat,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.guidesDirectory,
        builder: (context, state) => const GuidesDirectoryScreen(),
      ),
      GoRoute(
        path: RouteNames.guideProfile,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return GuidePublicProfileScreen(guideUid: uid);
        },
      ),
      GoRoute(
        path: RouteNames.activeCall,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ActiveCallScreen(sessionId: sessionId);
        },
      ),
    ],
  );
});
