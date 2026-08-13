import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/consultation_constants.dart';
import '../../auth/providers/auth_provider.dart';
import 'community_provider.dart';

/// Drives the presence heartbeat for the whole app from one place (see
/// AppShell) — a single foreground timer at
/// [ConsultationConstants.heartbeatInterval], not a write per screen and
/// never per-second. Pauses while the app is backgrounded; a resume fires
/// an immediate heartbeat so "back online" is instant rather than waiting
/// for the next tick.
class PresenceHeartbeatController with WidgetsBindingObserver {
  PresenceHeartbeatController(this._ref);

  final Ref _ref;
  Timer? _timer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _tick();
    _timer = Timer.periodic(
      ConsultationConstants.heartbeatInterval,
      (_) => _tick(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  void _tick() {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    // Fire-and-forget: a missed heartbeat just makes presence go stale a
    // little earlier, never a user-facing error.
    unawaited(
      _ref.read(communityServiceProvider).sendHeartbeat(uid).catchError((_) {}),
    );
  }
}

final presenceHeartbeatControllerProvider =
    Provider<PresenceHeartbeatController>((ref) {
  final controller = PresenceHeartbeatController(ref);
  ref.onDispose(controller.stop);
  return controller;
});
