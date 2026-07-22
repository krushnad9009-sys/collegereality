import 'package:flutter/foundation.dart';

/// Release-mode configuration flags for production builds.
class ReleaseConfig {
  ReleaseConfig._();

  static const String appName = 'College Reality';
  static const String packageId = 'com.collegereality.india';
  static const String version = '1.0.0';
  static const int buildNumber = 1;

  /// Analytics and crash reporting enabled outside debug mode.
  static bool get enableTelemetry => !kDebugMode;

  /// Verbose Firestore quota logging only in debug.
  static bool get enableDebugLogging => kDebugMode;
}
