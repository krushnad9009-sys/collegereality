import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/crashlytics_service.dart';
import 'onboarding_location_resolver.dart';

/// The OS permissions requested by the combined Permissions & Terms screen.
/// No photo/storage permission: uploads go through the system picker
/// (file_picker), which needs none, and Play restricts READ_MEDIA_IMAGES. Every method NEVER throws: a failure of any kind degrades to
/// "not granted", because permissions are optional and must never block the
/// user from finishing onboarding.
///
/// Kept behind a class (and [onboardingPermissionServiceProvider]) so the
/// screen can be tested without native plugins.
class OnboardingPermissionService {
  const OnboardingPermissionService();

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
