import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/firebase_bootstrap.dart';
import '../../../core/bootstrap/native_splash.dart';

void _log(String message) {
  if (kDebugMode) debugPrint('[SplashScreen] $message');
}

/// `SharedPreferences.getInstance()` has no timeout of its own -- on Flutter
/// Web it goes through a plugin-channel call that, in rare cases (plugin
/// registration not yet settled, storage access blocked), can simply never
/// resolve. Bounded here so a stuck prefs read can never hold up the entire
/// splash sequence; `hasSeenOnboarding` defaults to `true` on failure so a
/// returning user isn't re-shown onboarding just because local storage
/// glitched once.
const _kPrefsTimeout = Duration(seconds: 3);

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
  Timer? _hardFallbackTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeNativeSplashOnce();
      _navigateWhenReady();
    });
    // Absolute backstop: if `_navigateWhenReady` (and its own
    // `.timeout(_kSplashTimeout)`) somehow never lands a navigation —
    // e.g. `_goTo` wedged with `_navigating == true` — force the user off
    // the splash. Never redirect to the initial route ('/') itself; that
    // would just rebuild this screen.
    _hardFallbackTimer = Timer(_kSplashTimeout + const Duration(seconds: 2), () {
      if (!mounted || _navigated) return;
      _log('HARD FALLBACK fired -- forcing navigation to login');
      _forceNavigate(RouteNames.login);
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

  Future<void> _navigateWhenReady() async {
    if (_navigated) return;

    try {
      await _resolveAndNavigate().timeout(_kSplashTimeout);
    } catch (e, st) {
      debugPrint('Splash navigation error: $e\n$st');
      // Use the force path: a normal `_goTo` no-ops if `_navigating` is
      // still true from a `_resolveAndNavigate` that hung mid-`_goTo`.
      _forceNavigate(RouteNames.login);
    }
  }

  Future<void> _resolveAndNavigate() async {
    _log('START resolveAndNavigate');

    _log('START firebaseBootstrap+minimumDelay');
    await Future.wait([
      Future<void>.delayed(_kMinimumSplashDuration),
      FirebaseBootstrap.ensureInitialized(),
    ]);
    _log('SUCCESS firebaseBootstrap+minimumDelay');

    bool hasSeenOnboarding = true;
    try {
      _log('START SharedPreferences.getInstance');
      final prefs =
          await SharedPreferences.getInstance().timeout(_kPrefsTimeout);
      hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      _log('SUCCESS SharedPreferences.getInstance -- hasSeenOnboarding=$hasSeenOnboarding');
    } catch (e) {
      _log('FAILED SharedPreferences.getInstance: ${e.runtimeType} $e -- defaulting hasSeenOnboarding=true');
    }

    // Wait for Firebase Auth to restore persisted session (critical on web).
    final auth = FirebaseAuth.instance;
    User? user;
    try {
      _log('START authStateChanges.first');
      user = await auth.authStateChanges().first.timeout(
            const Duration(seconds: 5),
          );
      _log('SUCCESS authStateChanges.first -- isLoggedIn=${user != null}');
    } catch (e) {
      _log('FAILED authStateChanges.first: ${e.runtimeType} $e -- falling back to currentUser');
      user = auth.currentUser;
    }

    if (!mounted || _navigated || _navigating) {
      _log('ABORT resolveAndNavigate -- mounted=$mounted navigated=$_navigated navigating=$_navigating');
      return;
    }

    final isLoggedIn = user != null;

    if (isLoggedIn) {
      _log('SUCCESS resolveAndNavigate -- routing to home');
      await _goTo(RouteNames.home);
    } else if (hasSeenOnboarding) {
      _log('SUCCESS resolveAndNavigate -- routing to login');
      await _goTo(RouteNames.login);
    } else {
      _log('SUCCESS resolveAndNavigate -- routing to onboarding');
      await _goTo(RouteNames.onboarding);
    }
  }

  /// Navigate off the splash immediately, bypassing the exit fade and the
  /// `_navigating` guard. Only for the timeout / hard-fallback paths.
  void _forceNavigate(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    removeNativeSplashOnce();
    _log('forceNavigate -- context.go($route)');
    context.go(route);
  }

  Future<void> _goTo(String route) async {
    if (_navigating || _navigated || !mounted) return;
    _navigating = true;

    // The fade-out animation only advances on delivered frames; a
    // backgrounded/hidden tab (a real possibility right after a refresh,
    // e.g. the user already switched away) can stall ticker callbacks
    // indefinitely. Bounded so navigation always proceeds either way.
    try {
      await _exitController.forward().timeout(_kExitFadeDuration * 3);
    } catch (_) {
      // Timed out or ticker disposed mid-animation -- proceed regardless.
    }
    if (!mounted) return;

    _navigated = true;
    _log('navigating -- context.go($route)');
    context.go(route);
  }

  @override
  void dispose() {
    _hardFallbackTimer?.cancel();
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
