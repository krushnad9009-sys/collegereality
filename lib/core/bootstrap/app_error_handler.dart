import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Global crash and exception handling for production builds.
class AppErrorHandler {
  AppErrorHandler._();

  static bool _initialized = false;

  static void install() {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _record(
        details.exception,
        details.stack,
        label: details.library ?? 'FlutterError',
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _record(error, stack, label: 'PlatformDispatcher');
      return true;
    };
  }

  static void _record(
    Object error,
    StackTrace? stack, {
    required String label,
  }) {
    developer.log(
      label,
      error: error,
      stackTrace: stack,
      name: 'CollegeReality',
    );

    if (kReleaseMode) {
      // Enable Sentry in release builds with:
      // flutter build --dart-define=SENTRY_DSN=your_dsn
      assert(() {
        developer.log(
          'Configure SENTRY_DSN for remote crash reporting in production.',
          name: 'CollegeReality',
        );
        return true;
      }());
    }
  }
}
