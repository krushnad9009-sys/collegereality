import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../services/crashlytics_service.dart';

/// Global crash and exception handling for production builds.
class AppErrorHandler {
  AppErrorHandler._();

  static bool _initialized = false;

  static void install() {
    if (_initialized) return;
    _initialized = true;

    if (!kDebugMode) {
      // Crashlytics owns FlutterError.onError in release via CrashlyticsService.
      return;
    }

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      developer.log(
        details.library ?? 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
        name: 'CollegeReality',
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log(
        'PlatformDispatcher',
        error: error,
        stackTrace: stack,
        name: 'CollegeReality',
      );
      return true;
    };
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    developer.log(
      reason ?? 'NonFatal',
      error: error,
      stackTrace: stack,
      name: 'CollegeReality',
    );
    await CrashlyticsService.recordError(error, stack, reason: reason);
  }
}
