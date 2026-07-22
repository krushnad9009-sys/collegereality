import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics wrapper for production event and screen tracking.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  static FirebaseAnalytics get instance => _analytics;

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) return;
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  static Future<void> logLogin({required String method}) async {
    if (kDebugMode) return;
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp({required String method}) async {
    if (kDebugMode) return;
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logSearch({required String searchTerm}) async {
    if (kDebugMode) return;
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  static Future<void> setUserId(String? userId) async {
    if (kDebugMode) return;
    await _analytics.setUserId(id: userId);
  }
}
