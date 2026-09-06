import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

bool _removed = false;

/// Removes the pre-Flutter splash exactly once, safely.
///
/// `FlutterNativeSplash.preserve()` in `main()` keeps the splash on screen
/// until something calls `.remove()`. Every path that gets a real Flutter
/// frame in front of the user funnels through here — the router's first
/// redirect (and a safety timer beside it), `SplashScreen`, and
/// `FirebaseInitializingScreen` — so a hang or thrown error in any single
/// path can never leave the user staring at a frozen splash.
///
/// Idempotent and exception-safe: safe to call from many places and early.
void removeNativeSplashOnce() {
  if (_removed) return;
  _removed = true;
  try {
    FlutterNativeSplash.remove();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[nativeSplash] remove() failed (ignored): $e');
    }
  }
}
