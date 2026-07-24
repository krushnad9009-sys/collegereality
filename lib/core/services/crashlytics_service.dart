import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics integration for release crash reporting.
/// Crashlytics is not supported on web — all methods no-op there.
class CrashlyticsService {
  CrashlyticsService._();

  static bool get _supported => !kIsWeb;

  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    if (!_supported) return;

    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (_) {
      return;
    }

    if (kDebugMode) return;

    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (kDebugMode || !_supported) return;
    await _crashlytics.recordError(
      error,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }

  static Future<void> log(String message) async {
    if (kDebugMode || !_supported) return;
    await _crashlytics.log(message);
  }

  static Future<void> setUserId(String userId) async {
    if (kDebugMode || !_supported) return;
    await _crashlytics.setUserIdentifier(userId);
  }
}
