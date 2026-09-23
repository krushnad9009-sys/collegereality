import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

/// Which device-security condition(s), if any, should block app usage.
class DeviceSecurityStatus {
  final bool isRooted;
  final bool isDeveloperModeEnabled;
  final bool isUsbDebuggingEnabled;

  const DeviceSecurityStatus({
    this.isRooted = false,
    this.isDeveloperModeEnabled = false,
    this.isUsbDebuggingEnabled = false,
  });

  /// Root/jailbreak and Developer Options are both hard blocks. USB
  /// debugging alone is reported (and shown) but folded into the same
  /// "Developer Options" condition in practice -- enabling USB debugging
  /// requires Developer Options to already be on, so `isUsbDebuggingEnabled
  /// == true` never occurs with `isDeveloperModeEnabled == false` on a real
  /// device. Kept as a separate field anyway so the block screen can name
  /// the specific reason.
  bool get isBlocked => isRooted || isDeveloperModeEnabled;

  static const safe = DeviceSecurityStatus();

  @override
  String toString() =>
      'DeviceSecurityStatus(isRooted: $isRooted, '
      'isDeveloperModeEnabled: $isDeveloperModeEnabled, '
      'isUsbDebuggingEnabled: $isUsbDebuggingEnabled)';
}

/// Root/jailbreak + Android Developer Options/USB-debugging detection,
/// gating access in release builds only.
///
/// Deliberately fails OPEN (treats the device as safe) on any error or
/// timeout -- the same "never trap a legitimate user behind a flaky native
/// call" principle every other boot-time check in this app already follows
/// (see SplashScreen, FirebaseBootstrap, the presence heartbeat). Since
/// client-side root/dev-mode detection is a deterrent rather than a hard
/// security boundary anyway (a sufficiently determined attacker can defeat
/// it regardless of how this fails), a false negative here is far less
/// harmful than every legitimate user getting locked out whenever the
/// safe_device plugin call is momentarily unreliable.
class DeviceSecurityService {
  DeviceSecurityService._();

  static const _timeout = Duration(seconds: 5);

  /// Cached so `check()`'s native round-trip only ever runs once per app
  /// process -- both the eager `main()` kick-off and the router's own read
  /// (via deviceSecurityStatusProvider) resolve to the SAME in-flight/
  /// completed future rather than issuing the platform-channel call twice.
  static Future<DeviceSecurityStatus>? _inFlight;

  /// Call from `main()` before `runApp()`, unawaited -- exactly like
  /// FirebaseBootstrap.ensureInitialized() in this same file -- so the
  /// native round-trip is already underway (often already resolved) by the
  /// time the router's first redirect needs the result, instead of paying
  /// its full cost cold on the first navigation.
  static Future<DeviceSecurityStatus> prewarm() => _inFlight ??= _check();

  /// Returns the cached result if [prewarm] (or a previous call) already
  /// ran; otherwise starts the check now.
  static Future<DeviceSecurityStatus> check() => _inFlight ??= _check();

  /// Forces a fresh check, discarding any cached result -- used by the
  /// block screen's "Retry / Refresh Status" button once the user says
  /// they've turned Developer Options back off.
  static Future<DeviceSecurityStatus> recheck() {
    _inFlight = null;
    return check();
  }

  static Future<DeviceSecurityStatus> _check() async {
    // Root/Developer-Options detection is a mobile-only concept.
    // safe_device's MethodChannel has no web implementation -- every call
    // there would throw MissingPluginException (which the package itself
    // already catches and treats as "not detected"); this early return
    // just skips the pointless round trip.
    if (kIsWeb) return DeviceSecurityStatus.safe;

    // Never blocks a debug/profile build: `flutter run` on a physical
    // device REQUIRES USB debugging (and therefore Developer Options) to
    // be on in the first place, so enforcing this outside release builds
    // would make local development on a real device impossible.
    if (!kReleaseMode) return DeviceSecurityStatus.safe;

    try {
      final results = await Future.wait([
        SafeDevice.isJailBroken,
        SafeDevice.isDevelopmentModeEnable,
        SafeDevice.isUsbDebuggingEnabled,
      ]).timeout(_timeout);
      return DeviceSecurityStatus(
        isRooted: results[0],
        isDeveloperModeEnabled: results[1],
        isUsbDebuggingEnabled: results[2],
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[DeviceSecurityService] check failed, treating device as safe: '
          '$e\n$st',
        );
      }
      return DeviceSecurityStatus.safe;
    }
  }
}
