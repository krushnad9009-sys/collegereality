import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/go_router_refresh_stream.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_announcements_screen.dart';
import '../../features/admin/screens/admin_college_edit_screen.dart';
import '../../features/admin/screens/admin_colleges_screen.dart';
import '../../features/admin/screens/admin_community_screen.dart';
import '../../features/admin/screens/admin_cr_score_screen.dart';
import '../../features/admin/screens/admin_export_screen.dart';
import '../../features/admin/screens/admin_merge_colleges_screen.dart';
import '../../features/admin/screens/admin_questions_screen.dart';
import '../../features/admin/screens/admin_reports_hub_screen.dart';
import '../../features/admin/screens/admin_reviews_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_verification_screen.dart';
import '../../features/ecosystem/screens/admin_ecosystem_hub_screen.dart';
import '../providers/super_admin_provider.dart';
import '../screens/access_denied_screen.dart';
import '../screens/super_admin_dashboard_screen.dart';
import '../screens/super_admin_login_screen.dart';
import '../screens/super_admin_moderation_hub_screen.dart';
import '../screens/super_admin_settings_screen.dart';
import 'super_admin_route_names.dart';

final superAdminRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = FirebaseAuth.instance;
  final authRefresh = GoRouterRefreshStream(firebaseAuth.authStateChanges());

  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: SuperAdminRouteNames.login,
    debugLogDiagnostics: false,
    refreshListenable: authRefresh,
    redirect: (context, state) async {
      final path = state.uri.path;
      final isLoggedIn = firebaseAuth.currentUser != null;
      final isPublicRoute = path == SuperAdminRouteNames.login ||
          path == SuperAdminRouteNames.accessDenied;

      if (!isLoggedIn) {
        return isPublicRoute ? null : SuperAdminRouteNames.login;
      }

      Future<bool> checkSuperAdmin() async {
        try {
          return await ref.read(isSuperAdminProvider.future);
        } catch (_) {
          return false;
        }
      }

      if (path == SuperAdminRouteNames.login) {
        final isSuperAdmin = await checkSuperAdmin();
        if (isSuperAdmin) return SuperAdminRouteNames.dashboard;
        return SuperAdminRouteNames.accessDenied;
      }

      if (path == SuperAdminRouteNames.accessDenied) {
        final isSuperAdmin = await checkSuperAdmin();
        if (isSuperAdmin) return SuperAdminRouteNames.dashboard;
        return null;
      }

      final isSuperAdmin = await checkSuperAdmin();
      if (!isSuperAdmin) return SuperAdminRouteNames.accessDenied;

      return null;
    },
    routes: [
      GoRoute(
        path: SuperAdminRouteNames.login,
        builder: (context, state) => const SuperAdminLoginScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.accessDenied,
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.dashboard,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.users,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.colleges,
        builder: (context, state) => const AdminCollegesScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.collegeNew,
        builder: (context, state) => const AdminCollegeEditScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.collegeEdit,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminCollegeEditScreen(collegeId: id);
        },
      ),
      GoRoute(
        path: SuperAdminRouteNames.mergeColleges,
        builder: (context, state) => const AdminMergeCollegesScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.crScore,
        builder: (context, state) => const AdminCrScoreScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.moderation,
        builder: (context, state) => const SuperAdminModerationHubScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.reviews,
        builder: (context, state) => const AdminReviewsScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.community,
        builder: (context, state) => const AdminCommunityScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.reports,
        builder: (context, state) => const AdminReportsHubScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.questions,
        builder: (context, state) => const AdminQuestionsScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.verification,
        builder: (context, state) => const AdminVerificationScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.notifications,
        builder: (context, state) => const AdminAnnouncementsScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.analytics,
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.settings,
        builder: (context, state) => const SuperAdminSettingsScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.export,
        builder: (context, state) => const AdminExportScreen(),
      ),
      GoRoute(
        path: SuperAdminRouteNames.ecosystem,
        builder: (context, state) => const AdminEcosystemHubScreen(),
      ),
    ],
  );
});
