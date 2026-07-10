import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import 'route_names.dart';

// Auth state redirect logic
final _authStateProvider = StateProvider<AuthRedirect>((ref) {
  return AuthRedirect.initial;
});

enum AuthRedirect {
  initial,
  authenticated,
  unauthenticated,
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = FirebaseAuth.instance;
  
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = firebaseAuth.currentUser != null;
      final isOnAuthPage = state.uri.path == RouteNames.login ||
          state.uri.path == RouteNames.signup ||
          state.uri.path == RouteNames.onboarding ||
          state.uri.path == RouteNames.splash;

      // If not logged in and not on auth page, redirect to login
      if (!isLoggedIn && !isOnAuthPage) {
        return RouteNames.login;
      }

      // If logged in and on auth page, redirect to home
      if (isLoggedIn && (state.uri.path == RouteNames.login ||
          state.uri.path == RouteNames.signup ||
          state.uri.path == RouteNames.onboarding)) {
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
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // Add more routes here as features are developed
    ],
  );
});
