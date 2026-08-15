import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/firebase_bootstrap.dart';

/// Maximum time to wait for Firebase/auth/prefs before forcing navigation.
/// Must comfortably exceed FirebaseBootstrap's own init timeout (5s) plus
/// the auth-state-restore timeout below (5s) plus the minimum splash
/// duration, so those inner, more specific timeouts get a chance to fire
/// (and log something useful) instead of this outer one masking them.
const _kSplashTimeout = Duration(seconds: 14);

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
    with SingleTickerProviderStateMixin {
  late AnimationController _exitController;
  bool _navigated = false;
  bool _navigating = false;
  bool _logoPrecached = false;
  bool _nativeSplashRemoved = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeNativeSplashWhenReady();
      _navigateWhenReady();
    });
  }

  void _setupAnimations() {
    _exitController = AnimationController(
      duration: _kExitFadeDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logoPrecached) {
      _logoPrecached = true;
      precacheImage(
        const AssetImage(_CollegeRealityLogo.assetPath),
        context,
      );
    }
  }

  void _removeNativeSplashWhenReady() {
    if (_nativeSplashRemoved || !mounted) return;
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
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
      Future<void>.delayed(_kMinimumSplashDuration),
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

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = _logoSizeForWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) {
            return Opacity(
              opacity: 1.0 - _exitController.value,
              child: child,
            );
          },
          child: Center(
            child: _CollegeRealityLogo(width: logoSize),
          ),
        ),
      ),
    );
  }

  double _logoSizeForWidth(double width) {
    if (width < 360) return 231;
    if (width < 600) return 269;
    return 310;
  }
}

class _CollegeRealityLogo extends StatelessWidget {
  const _CollegeRealityLogo({required this.width});

  final double width;

  static const assetPath = 'assets/icons/splash_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
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
