import 'package:flutter/foundation.dart';

import '../services/crashlytics_service.dart';

void _log(String message) {
  // debugPrint, not dart:developer's log() -- on Flutter Web, log()'s
  // `error:` parameter requires a JS-interop-safe value; passing a raw
  // exception object (e.g. a FirebaseException, which is exactly what
  // this handler exists to catch) crashes with "type 'X' is not a
  // subtype of type 'JavaScriptObject'" instead of logging anything.
  // That's especially bad here: this crashing INSIDE the app's own
  // global error handler could mask or replace the very error it was
  // reporting. debugPrint is a plain string sink with no such
  // constraint, and (like the original developer.log calls here)
  // intentionally not gated by kDebugMode.
  debugPrint('[AppErrorHandler] $message');
}

/// Global crash and exception handling for production builds.
class AppErrorHandler {
  AppErrorHandler._();

  static bool _initialized = false;

  static void install() {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _log('${details.library ?? 'FlutterError'}: ${details.exception}');
      if (kDebugMode) debugPrintStack(stackTrace: details.stack);
      if (!kDebugMode) {
        CrashlyticsService.recordError(
          details.exception,
          details.stack,
          fatal: true,
          reason: details.library,
        );
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _log('PlatformDispatcher: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
      if (!kDebugMode) {
        CrashlyticsService.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    _log('${reason ?? 'NonFatal'}: $error');
    if (kDebugMode) debugPrintStack(stackTrace: stack ?? StackTrace.current);
    await CrashlyticsService.recordError(error, stack, reason: reason);
  }
}
