import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/firebase_bootstrap.dart';

/// Maximum time to wait for Firebase/auth/prefs before forcing navigation.
const _kSplashTimeout = Duration(seconds: 8);

/// Minimum time the splash stays visible before exit fade.
const _kMinimumSplashDuration = Duration(milliseconds: 1600);

/// Exit fade duration before route navigation.
const _kExitFadeDuration = Duration(milliseconds: 380);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _exitController;
  late AnimationController _glowController;
  late AnimationController _driftController;
  late AnimationController _loadingController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _driftAnimation;
  bool _navigated = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateWhenReady());
  }

  void _setupAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 820),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: _kExitFadeDuration,
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 4200),
      vsync: this,
    )..repeat(reverse: true);

    _driftController = AnimationController(
      duration: const Duration(milliseconds: 6200),
      vsync: this,
    )..repeat(reverse: true);

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _fadeInAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.12, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _driftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  Future<void> _navigateWhenReady() async {
    if (_navigated) return;

    try {
      await _resolveAndNavigate().timeout(_kSplashTimeout);
    } catch (e, st) {
      debugPrint('Splash navigation error: $e\n$st');
      await _goTo(RouteNames.login);
    }
  }

  Future<void> _resolveAndNavigate() async {
    await Future.wait([
      Future.delayed(_kMinimumSplashDuration),
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

    if (!mounted || _navigated || _navigating) return;

    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final isLoggedIn = user != null;

    if (isLoggedIn) {
      await _goTo(RouteNames.home);
    } else if (hasSeenOnboarding) {
      await _goTo(RouteNames.login);
    } else {
      await _goTo(RouteNames.onboarding);
    }
  }

  Future<void> _goTo(String route) async {
    if (_navigating || _navigated || !mounted) return;
    _navigating = true;

    await _exitController.forward();
    if (!mounted) return;

    _navigated = true;
    context.go(route);
  }

  double _combinedOpacity() {
    return _fadeInAnimation.value * (1.0 - _exitController.value);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    _glowController.dispose();
    _driftController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = _logoSizeForWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _SplashBackground(
            glowValue: _glowAnimation,
            driftValue: _driftAnimation,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: Listenable.merge([_entryController, _exitController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _combinedOpacity(),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _CollegeRealityLogo(size: logoSize),
                          ),
                          AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: child,
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: logoSize * 0.36),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        Color(0xFF111827),
                                        Color(0xFF374151),
                                        Color(0xFF111827),
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ).createShader(bounds),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      'College Reality',
                                      style: AppTypography.display('College Reality').copyWith(
                                            fontSize: 34,
                                            color: AppTheme.gray900,
                                            letterSpacing: -1.0,
                                            height: 1.1,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Know the Reality Before You Take Admission',
                                  style: AppTypography.body('').copyWith(
                                        fontSize: 15,
                                        color: AppTheme.gray500,
                                        height: 1.5,
                                        letterSpacing: 0.1,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: logoSize * 0.5),
                          _SplashLoadingIndicator(controller: _loadingController),
                          const SizedBox(height: 18),
                          Text(
                            'Loading your experience…',
                            style: AppTypography.caption('').copyWith(
                                  color: AppTheme.gray400,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _logoSizeForWidth(double width) {
    if (width < 360) return 114;
    if (width < 600) return 132;
    return 152;
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({
    required this.glowValue,
    required this.driftValue,
  });

  final Animation<double> glowValue;
  final Animation<double> driftValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glowValue, driftValue]),
      builder: (context, _) {
        final glow = glowValue.value;
        final drift = driftValue.value;
        final height = MediaQuery.sizeOf(context).height;
        final width = MediaQuery.sizeOf(context).width;
        final minSide = math.min(width, height);

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFFFFFBF7), const Color(0xFFFDF8FF), glow)!,
                Color.lerp(const Color(0xFFF5F0FF), const Color(0xFFEEF4FF), glow)!,
                Color.lerp(const Color(0xFFF0F7FF), const Color(0xFFF8FAFF), glow)!,
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: height * (0.18 + drift * 0.04),
                left: -40,
                right: -40,
                child: Transform.rotate(
                  angle: -0.08 + drift * 0.04,
                  child: Container(
                    height: height * 0.42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.38),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _GlowOrb(
                top: -height * 0.08 + math.sin(drift * math.pi * 2) * 10,
                left: width * 0.55 + glow * 14,
                size: minSide * 0.72,
                color: AppTheme.primaryColor.withValues(alpha: 0.11 + glow * 0.04),
              ),
              _GlowOrb(
                bottom: -height * 0.06 - glow * 10,
                left: -width * 0.18 + drift * 18,
                size: minSide * 0.58,
                color: AppTheme.secondaryColor.withValues(alpha: 0.09 + glow * 0.03),
              ),
              _GlowOrb(
                top: height * 0.28 + math.cos(drift * math.pi * 2) * 8,
                left: -width * 0.06,
                size: minSide * 0.34,
                color: AppTheme.primaryLight.withValues(alpha: 0.07 + glow * 0.02),
              ),
              _GlowOrb(
                top: height * 0.08 - glow * 8,
                right: width * 0.04 - drift * 12,
                size: minSide * 0.22,
                color: const Color(0xFFF472B6).withValues(alpha: 0.06 + glow * 0.02),
              ),
              _GlowOrb(
                bottom: height * 0.22 + drift * 10,
                right: -width * 0.08,
                size: minSide * 0.40,
                color: AppTheme.accentColor.withValues(alpha: 0.05 + glow * 0.02),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final double size;
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollegeRealityLogo extends StatelessWidget {
  const _CollegeRealityLogo({required this.size});

  final double size;

  static const _assetPath = 'assets/icons/splash_logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.28),
                  blurRadius: size * 0.38,
                  spreadRadius: size * 0.04,
                ),
                BoxShadow(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.14),
                  blurRadius: size * 0.26,
                  spreadRadius: size * 0.01,
                ),
                BoxShadow(
                  color: AppTheme.primaryLight.withValues(alpha: 0.10),
                  blurRadius: size * 0.18,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          Image.asset(
            _assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ],
      ),
    );
  }
}

class _SplashLoadingIndicator extends StatelessWidget {
  const _SplashLoadingIndicator({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final phase = (controller.value + index * 0.22) % 1.0;
                  final scale = 0.55 + 0.45 * _pulse(phase);
                  final opacity = 0.35 + 0.65 * _pulse(phase);

                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: opacity),
                              AppTheme.primaryDark.withValues(alpha: opacity * 0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: opacity * 0.35),
                              blurRadius: 8,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 96,
                  height: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.gray200.withValues(alpha: 0.55),
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment(-1 + controller.value * 2, 0),
                        widthFactor: 0.42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0),
                                AppTheme.primaryColor.withValues(alpha: 0.85),
                                AppTheme.secondaryColor.withValues(alpha: 0.75),
                                AppTheme.primaryColor.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _pulse(double t) {
    if (t < 0.5) return Curves.easeOut.transform(t * 2);
    return Curves.easeIn.transform(2 - t * 2);
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
