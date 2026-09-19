import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/crashlytics_service.dart';

/// Sentinel the admin panel already filters out of region analytics -- used
/// instead of a fabricated default city so bad data never reaches Firestore.
const String kLocationNotProvided = 'Not Provided';

/// Outcome of the onboarding location step. Always produced (never thrown),
/// because the caller must persist *something* whether granted, denied, or
/// unresolvable.
class OnboardingLocationResult {
  /// The OS/browser permission was granted (position/city may still be
  /// unresolved -- see [state]/[city]).
  final bool granted;
  final String state;
  final String city;

  const OnboardingLocationResult({
    required this.granted,
    required this.state,
    required this.city,
  });

  static const OnboardingLocationResult notProvided = OnboardingLocationResult(
    granted: false,
    state: kLocationNotProvided,
    city: kLocationNotProvided,
  );

  static const OnboardingLocationResult grantedButUnresolved =
      OnboardingLocationResult(
    granted: true,
    state: kLocationNotProvided,
    city: kLocationNotProvided,
  );
}

Future<T> _within<T>(Future<T> Function() run, Duration? limit) async {
  final future = run();
  return limit == null ? future : future.timeout(limit);
}

void _report(Object e, StackTrace st, String stage) {
  // A timeout is an expected outcome here, not a crash worth recording.
  if (e is TimeoutException) return;
  CrashlyticsService.recordError(
    e,
    st,
    reason: 'PermissionsOnboarding (location: $stage)',
  );
}

/// Resolves the user's state/city for the permissions onboarding screen.
///
/// Never throws and never waits longer than roughly
/// `permissionPromptTimeout + fetchTimeout + fetchTimeout`. Any failure --
/// denied, timed out, services off, geocoding unavailable -- degrades to
/// [kLocationNotProvided] instead of hanging the screen.
///
/// Why explicit Dart-side timeouts: `geolocator_web` ignores `timeLimit`
/// (it hands the browser microseconds where milliseconds are expected, and
/// defaults to one day), and its `requestPermission()` blocks on a full
/// position fix. An ignored browser prompt would otherwise spin forever.
///
/// [permissionPromptTimeout] bounds the permission check + prompt. It is
/// applied on web only by default: the native OS dialog is modal, so
/// cutting the user off mid-decision would move on underneath a visible
/// dialog.
Future<OnboardingLocationResult> resolveOnboardingLocation({
  Duration? permissionPromptTimeout =
      kIsWeb ? const Duration(seconds: 8) : null,
  Duration fetchTimeout = const Duration(seconds: 8),
}) async {
  try {
    final permission = await _within(() async {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      return p;
    }, permissionPromptTimeout);

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return OnboardingLocationResult.notProvided;
    }

    final Position position;
    try {
      position = await _within(() async {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const LocationServiceDisabledException();
        }
        return Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: fetchTimeout,
          ),
        );
      }, fetchTimeout);
    } on LocationServiceDisabledException {
      return OnboardingLocationResult.notProvided;
    } catch (e, st) {
      _report(e, st, 'position');
      return OnboardingLocationResult.grantedButUnresolved;
    }

    // geocoding has no web implementation -- calling it there throws.
    if (kIsWeb) return OnboardingLocationResult.grantedButUnresolved;

    try {
      final placemarks = await _within(
        () => placemarkFromCoordinates(position.latitude, position.longitude),
        fetchTimeout,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final state = placemark?.administrativeArea?.trim();
      final city = _firstNonEmpty([
        placemark?.locality,
        placemark?.subAdministrativeArea,
      ]);
      return OnboardingLocationResult(
        granted: true,
        state: (state == null || state.isEmpty) ? kLocationNotProvided : state,
        city: city ?? kLocationNotProvided,
      );
    } catch (e, st) {
      // Permission and position succeeded -- only the name lookup failed.
      _report(e, st, 'geocoding');
      return OnboardingLocationResult.grantedButUnresolved;
    }
  } catch (e, st) {
    _report(e, st, 'permission');
    return OnboardingLocationResult.notProvided;
  }
}

String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}
