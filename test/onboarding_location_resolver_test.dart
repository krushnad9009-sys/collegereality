import 'dart:async';

import 'package:college_reality_india/features/onboarding/services/onboarding_location_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({
    this.checkResult = LocationPermission.denied,
    this.request,
    this.serviceEnabled = true,
    this.position,
  });

  final LocationPermission checkResult;
  final Future<LocationPermission> Function()? request;
  final bool serviceEnabled;
  final Future<Position> Function()? position;

  @override
  Future<LocationPermission> checkPermission() async => checkResult;

  @override
  Future<LocationPermission> requestPermission() =>
      request?.call() ?? Future.value(LocationPermission.denied);

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      position?.call() ?? Completer<Position>().future;
}

Position _somewhere() => Position(
      longitude: 77.2,
      latitude: 28.6,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

const _short = Duration(milliseconds: 60);

void main() {
  test('ignored permission prompt times out to Not Provided', () async {
    GeolocatorPlatform.instance = _FakeGeolocator(
      request: () => Completer<LocationPermission>().future,
    );

    final result = await resolveOnboardingLocation(
      permissionPromptTimeout: _short,
      fetchTimeout: _short,
    ).timeout(const Duration(seconds: 2));

    expect(result.granted, isFalse);
    expect(result.state, kLocationNotProvided);
    expect(result.city, kLocationNotProvided);
  });

  test('a hanging position fix times out but keeps granted', () async {
    GeolocatorPlatform.instance = _FakeGeolocator(
      checkResult: LocationPermission.whileInUse,
    );

    final result = await resolveOnboardingLocation(
      permissionPromptTimeout: _short,
      fetchTimeout: _short,
    ).timeout(const Duration(seconds: 2));

    expect(result.granted, isTrue);
    expect(result.city, kLocationNotProvided);
  });

  test('denied and deniedForever fall back without a position call', () async {
    for (final denied in [
      LocationPermission.denied,
      LocationPermission.deniedForever,
    ]) {
      GeolocatorPlatform.instance = _FakeGeolocator(
        checkResult: denied,
        request: () async => denied,
      );
      final result = await resolveOnboardingLocation(
        permissionPromptTimeout: _short,
        fetchTimeout: _short,
      );
      expect(result.granted, isFalse, reason: '$denied');
    }
  });

  test('a throwing permission request never propagates', () async {
    GeolocatorPlatform.instance = _FakeGeolocator(
      request: () async => throw StateError('boom'),
    );

    final result = await resolveOnboardingLocation(
      permissionPromptTimeout: _short,
      fetchTimeout: _short,
    );

    expect(result.granted, isFalse);
  });

  test('location services off falls back to Not Provided', () async {
    GeolocatorPlatform.instance = _FakeGeolocator(
      checkResult: LocationPermission.whileInUse,
      serviceEnabled: false,
    );

    final result = await resolveOnboardingLocation(
      permissionPromptTimeout: _short,
      fetchTimeout: _short,
    );

    expect(result.granted, isFalse);
  });

  test('geocoding failure after a fix keeps granted, city Not Provided',
      () async {
    GeolocatorPlatform.instance = _FakeGeolocator(
      checkResult: LocationPermission.whileInUse,
      position: () async => _somewhere(),
    );

    final result = await resolveOnboardingLocation(
      permissionPromptTimeout: _short,
      fetchTimeout: _short,
    );

    expect(result.granted, isTrue);
    expect(result.state, kLocationNotProvided);
  });
}
