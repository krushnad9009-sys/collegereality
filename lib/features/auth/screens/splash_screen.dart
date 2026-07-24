import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/firebase_bootstrap.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateWhenReady();
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
    SharedPreferences? prefs;
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 450)),
      FirebaseBootstrap.ensureInitialized(),
      SharedPreferences.getInstance().then((p) => prefs = p),
    ]);

    if (!mounted) return;

    final hasSeenOnboarding = prefs?.getBool('hasSeenOnboarding') ?? false;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (!mounted) return;

    if (isLoggedIn) {
      context.go(RouteNames.home);
    } else if (hasSeenOnboarding) {
      context.go(RouteNames.login);
    } else {
      context.go(RouteNames.onboarding);
    }
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
