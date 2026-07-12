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
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = FirebaseAuth.instance;

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
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
        path: RouteNames.collegeSearch,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          final city = state.uri.queryParameters['city'];
          final stateParam = state.uri.queryParameters['state'];
          return CollegeSearchScreen(
            initialQuery: query,
            initialCity: city,
            initialState: stateParam,
          );
        },
      ),
      GoRoute(
        path: RouteNames.collegeDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CollegeDetailScreen(collegeId: id);
        },
      ),
    ],
  );
});
