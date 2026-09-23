import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_security_service.dart';

/// The app's device-security status for this session. Deliberately NOT
/// `.autoDispose` -- the router's redirect callback (app_router.dart)
/// reads this on every navigation via `ref.read(...future)`, and it must
/// keep serving the same cached result rather than re-running the native
/// check (and re-paying its timeout budget) every time nothing is actively
/// watching it between navigations.
final deviceSecurityStatusProvider =
    FutureProvider<DeviceSecurityStatus>((ref) => DeviceSecurityService.check());
