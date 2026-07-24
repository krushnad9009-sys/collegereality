import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/firebase_bootstrap.dart';

/// Maximum time to wait for Firebase/auth/prefs before forcing navigation.
const _kSplashTimeout = Duration(seconds: 8);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateWhenReady());
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateWhenReady() async {
    if (_navigated) return;

    try {
      await _resolveAndNavigate().timeout(_kSplashTimeout);
    } catch (e, st) {
      debugPrint('Splash navigation error: $e\n$st');
      _goTo(RouteNames.login);
    }
  }

  Future<void> _resolveAndNavigate() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 400)),
      FirebaseBootstrap.ensureInitialized(),
    ]);

    final prefs = await SharedPreferences.getInstance();

    // Wait for Firebase Auth to restore persisted session (critical on web).
    final auth = FirebaseAuth.instance;
    User? user;
    try {
      user = await auth.authStateChanges().first.timeout(
            const Duration(seconds: 5),
          );
    } catch (_) {
      user = auth.currentUser;
    }

    if (!mounted || _navigated) return;

    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final isLoggedIn = user != null;

    if (isLoggedIn) {
      _goTo(RouteNames.home);
    } else if (hasSeenOnboarding) {
      _goTo(RouteNames.login);
    } else {
      _goTo(RouteNames.onboarding);
    }
  }

  void _goTo(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(route);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 62,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'College Reality',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Know the Reality Before You Take Admission',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading your experience…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolves the post-splash route without requiring a BuildContext (testable).
String resolveSplashRoute({
  required bool isLoggedIn,
  required bool hasSeenOnboarding,
}) {
  if (isLoggedIn) return RouteNames.home;
  if (hasSeenOnboarding) return RouteNames.login;
  return RouteNames.onboarding;
}
