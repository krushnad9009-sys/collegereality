import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

void _log(String message) {
  // debugPrint, not dart:developer's log() -- on Flutter Web, log()'s
  // `error:` parameter requires a JS-interop-safe value; passing a raw
  // FirebaseException (exactly what setPersistence()/Firestore settings
  // throw here) crashes with "type 'FirebaseException' is not a subtype
  // of type 'JavaScriptObject'" instead of logging anything. That crash
  // happened INSIDE this file's own catch blocks, before runApp() ever
  // fired, which is worse than the error it was trying to report.
  // debugPrint is a plain string sink with no such constraint, and (like
  // the original developer.log calls here) intentionally not gated by
  // kDebugMode -- these are operational "continuing in degraded mode"
  // notes worth keeping visible in production too.
  debugPrint('[FirebaseBootstrap] $message');
}

/// Non-blocking Firebase initialization started from [main] and awaited on splash.
///
/// Hardened against hard-refresh/multi-tab hangs on Flutter Web: a stuck or
/// rejected auth-persistence / Firestore-persistence call (e.g. another tab
/// holding the IndexedDB persistence lock, or third-party storage blocked in
/// private browsing) must never prevent `Firebase.initializeApp` itself from
/// completing, and this whole step is bounded by a timeout so `main()` can
/// always reach `runApp()` — an indefinitely pending native splash was the
/// root cause of "app doesn't come back after refresh" reports.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  // Kept comfortably under SplashScreen's own outer timeout (which also has
  // to budget time afterwards for auth-state restoration) so this bootstrap
  // always has a chance to fail *fast* on its own terms, instead of the
  // outer splash timeout firing first and masking what actually happened.
  static const _initTimeout = Duration(seconds: 5);
  // IndexedDB-backed calls (auth/Firestore persistence) are the actual hang
  // risk on web — a Promise from the JS interop layer that never settles
  // (storage blocked/partitioned, another tab holding the lock, private
  // browsing) is not caught by try/catch, only by its own timeout.
  static const _persistenceCallTimeout = Duration(seconds: 3);

  static Future<void>? _initFuture;
  static bool _configured = false;

  static Future<void> ensureInitialized() {
    _initFuture ??= _initialize().timeout(
      _initTimeout,
      onTimeout: () {
        _log(
          'Firebase init exceeded $_initTimeout — continuing without it so '
          'the UI can still render (splash/auth flow will retry).',
        );
      },
    ).catchError((Object e, StackTrace st) {
      // A *thrown* init failure (bad options, plugin error) must not leave
      // a rejected future memoised forever — every later awaiter (router,
      // splash, FCM) would then synchronously rethrow it. Swallow here;
      // callers already treat "Firebase not ready" as a soft state and
      // FirebaseInitializingScreen offers an explicit retry.
      _log('Firebase init threw — continuing without it: $e\n$st');
    });
    return _initFuture!;
  }

  static bool get isInitialized => _configured;

  /// Discards the memoised init result so the next [ensureInitialized]
  /// genuinely re-runs `Firebase.initializeApp()`. Used by
  /// `FirebaseInitializingScreen`'s "Retry" action after a boot stall.
  static void resetForRetry() {
    _initFuture = null;
    _configured = false;
  }

  static Future<void> _initialize() async {
    // Guard against a duplicate-app throw: a slow first initializeApp() can
    // still be in flight (or have completed after our timeout) when a
    // retry calls in here again.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Persistence is a best-effort offline/session convenience. It must
    // never block app startup or crash it — e.g. another open tab holding
    // the IndexedDB lock, storage blocked in private browsing, or a
    // sandboxed webview without IndexedDB at all.
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance
            .setPersistence(Persistence.LOCAL)
            .timeout(_persistenceCallTimeout);
      } catch (e, st) {
        _log('Auth persistence setup failed (continuing without it): $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } catch (e, st) {
      _log('Firestore persistence setup failed (continuing without it): $e');
      if (kDebugMode) debugPrintStack(stackTrace: st);
    }

    _configured = true;
  }
}
