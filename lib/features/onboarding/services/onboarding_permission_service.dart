import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/crashlytics_service.dart';
import 'onboarding_location_resolver.dart';

/// The three OS permissions requested by the combined Permissions & Terms
/// screen. Every method NEVER throws: a failure of any kind degrades to
/// "not granted", because permissions are optional and must never block the
/// user from finishing onboarding.
///
/// Kept behind a class (and [onboardingPermissionServiceProvider]) so the
/// screen can be tested without native plugins.
class OnboardingPermissionService {
  const OnboardingPermissionService();

  /// Gallery / photo library. Flutter Web's file picker is a plain
  /// `<input type=file>` -- there is no OS permission to request there, so
  /// it counts as granted.
  Future<bool> requestPhotos() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    } catch (e, st) {
      CrashlyticsService.recordError(
        e,
        st,
        reason: 'PermissionsTerms (photos)',
      );
      return false;
    }
  }

  /// Push notifications. Mirrors `FirebaseMessagingService.initialize()`,
  /// which also only requests this on non-web -- web push isn't wired up in
  /// this app. Requests `FirebaseMessaging` directly (not the messaging
  /// service) to avoid also doing token save / router wiring here.
  Future<bool> requestNotifications() async {
    if (kIsWeb) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e, st) {
      CrashlyticsService.recordError(
        e,
        st,
        reason: 'PermissionsTerms (notifications)',
      );
      return false;
    }
  }

  /// Location, resolved to a state/city (see [resolveOnboardingLocation],
  /// which is itself bounded and never throws).
  Future<OnboardingLocationResult> requestLocation() =>
      resolveOnboardingLocation();
}

final onboardingPermissionServiceProvider =
    Provider<OnboardingPermissionService>(
      (ref) => const OnboardingPermissionService(),
    );
