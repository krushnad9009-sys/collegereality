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

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateWhenReady());
  }

  void _setupAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.78, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.18, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController.forward();
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
    _entryController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AnimatedSplashBackground(glowValue: _glowAnimation),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: const CollegeRealityLogo(size: 120),
                                ),
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
                                    const SizedBox(height: 36),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'College Reality',
                                        style: AppTypography.display('College Reality').copyWith(
                                              fontSize: 32,
                                              color: AppTheme.gray900,
                                              letterSpacing: -0.8,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Know the Reality Before You Take Admission',
                                      style: AppTypography.body('').copyWith(
                                            fontSize: 15,
                                            color: AppTheme.gray500,
                                            height: 1.45,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 56),
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading your experience…',
                                style: AppTypography.caption('').copyWith(
                                      color: AppTheme.gray400,
                                    ),
                              ),
                            ],
                          ),
                        ),
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
}

class _AnimatedSplashBackground extends StatelessWidget {
  const _AnimatedSplashBackground({required this.glowValue});

  final Animation<double> glowValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowValue,
      builder: (context, _) {
        final t = glowValue.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF8FAFF),
                Color.lerp(const Color(0xFFEEF2FF), const Color(0xFFF0F9FF), t)!,
                const Color(0xFFFAFBFE),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -140 + t * 12,
                right: -90,
                child: _GlowOrb(
                  size: 320,
                  color: AppTheme.primaryColor.withValues(alpha: 0.10 + t * 0.04),
                ),
              ),
              Positioned(
                bottom: -120 - t * 8,
                left: -70,
                child: _GlowOrb(
                  size: 280,
                  color: AppTheme.secondaryColor.withValues(alpha: 0.08 + t * 0.03),
                ),
              ),
              Positioned(
                top: MediaQuery.sizeOf(context).height * 0.32,
                left: -50 + t * 20,
                child: _GlowOrb(
                  size: 180,
                  color: AppTheme.primaryLight.withValues(alpha: 0.06 + t * 0.02),
                ),
              ),
              Positioned(
                top: MediaQuery.sizeOf(context).height * 0.12,
                right: 40 - t * 16,
                child: _GlowOrb(
                  size: 100,
                  color: AppTheme.accentColor.withValues(alpha: 0.05 + t * 0.02),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class CollegeRealityLogo extends StatelessWidget {
  final double size;

  const CollegeRealityLogo({this.size = 96, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              blurRadius: size * 0.32,
              spreadRadius: size * 0.02,
              offset: Offset(0, size * 0.1),
            ),
            BoxShadow(
              color: AppTheme.secondaryColor.withValues(alpha: 0.12),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.04),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _CollegeRealityLogoPainter(),
          size: Size(size, size),
        ),
      ),
    );
  }
}

class _CollegeRealityLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Outer soft ring
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.primaryLight.withValues(alpha: 0.18),
            AppTheme.primaryColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.48)),
    );

    // Main rounded-square badge
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.82, height: w * 0.82),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF4F46E5),
            Color(0xFF4338CA),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(bgRect.outerRect),
    );

    // Inner highlight sheen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.1, w * 0.76, h * 0.38),
        Radius.circular(w * 0.18),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Graduation cap
    final capTop = Path()
      ..moveTo(cx - w * 0.26, h * 0.4)
      ..lineTo(cx, h * 0.3)
      ..lineTo(cx + w * 0.26, h * 0.4)
      ..lineTo(cx, h * 0.5)
      ..close();
    canvas.drawPath(capTop, Paint()..color = Colors.white.withValues(alpha: 0.96));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.54), width: w * 0.42, height: h * 0.09),
        Radius.circular(w * 0.035),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Tassel
    canvas.drawLine(
      Offset(cx + w * 0.17, h * 0.36),
      Offset(cx + w * 0.23, h * 0.58),
      Paint()
        ..color = AppTheme.secondaryColor
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.23, h * 0.62),
      w * 0.042,
      Paint()..color = AppTheme.secondaryColor,
    );

    // Star accent — "reality" insight
    _drawStar(canvas, Offset(cx - w * 0.13, h * 0.66), w * 0.085, AppTheme.warningColor);

    // Subtle "CR" monogram hint at bottom
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CR',
        style: TextStyle(
          fontSize: w * 0.11,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.22),
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, h * 0.72));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = (i * math.pi / points) - math.pi / 2;
      if (i == 0) {
        path.moveTo(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      } else {
        path.lineTo(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
