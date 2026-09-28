import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/consultation_constants.dart';
import '../../auth/providers/auth_provider.dart';
import 'community_provider.dart';

/// The ONLY writer of the current user's `isOnline` flag, for the whole
/// app. Started by AppShell (and ChatScreen, which lives outside the shell
/// route); `start()` is idempotent.
///
/// Lifecycle:
/// * resumed                  → `isOnline: true` now, then a heartbeat
///                              every [ConsultationConstants.heartbeatInterval]
/// * paused / hidden / detached → timer stopped, `isOnline: false` +
///                              `lastSeenAt` written immediately
/// * inactive                 → ignored. It is transient (notification
///                              shade, app switcher, permission/biometric
///                              prompt, incoming-call overlay) and always
///                              followed by `paused` if the app really
///                              leaves the foreground; reacting to it would
///                              flap the user offline/online constantly.
///
/// A force-quit / crashed app may never deliver `detached` (or the write
/// may not flush), so viewers additionally treat presence as offline once
/// `lastSeenAt` is older than [ConsultationConstants.presenceStaleAfter]
/// (see UserPresenceModel.isActiveNow).
class PresenceHeartbeatController with WidgetsBindingObserver {
  PresenceHeartbeatController(this._ref);

  final Ref _ref;
  Timer? _timer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _goOnline();
  }

  void stop() {
    _cancelTimer();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  /// Explicit offline write for sign-out: must run while the user is still
  /// authenticated, or Firestore rules reject it. Also stops the observer
  /// so a lifecycle event can't re-mark a signed-out session online; the
  /// next AppShell mount after sign-in calls [start] again.
  Future<void> markOfflineAndStop() async {
    final uid = _ref.read(currentUserProvider)?.uid;
    stop();
    if (uid == null) return;
    await _ref
        .read(communityServiceProvider)
        .updatePresence(uid, isOnline: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _goOnline();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _goOffline();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _goOnline() {
    _cancelTimer();
    _write(online: true);
    _timer = Timer.periodic(
      ConsultationConstants.heartbeatInterval,
      (_) => _write(online: true),
    );
  }

  void _goOffline() {
    // Both `hidden` and `paused` arrive on the way to the background; the
    // timer check makes the second one a no-op instead of a duplicate write.
    if (_timer == null) return;
    _cancelTimer();
    _write(online: false);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _write({required bool online}) {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    // Fire-and-forget: a missed write just makes presence go stale a little
    // earlier, never a user-facing error -- but log it, since a write that
    // always fails (rules, missing doc) is otherwise invisible.
    unawaited(
      _ref
          .read(communityServiceProvider)
          .updatePresence(uid, isOnline: online)
          .catchError((Object e) {
        debugPrint('[presence] ${online ? 'online' : 'offline'} write failed: $e');
      }),
    );
  }
}

final presenceHeartbeatControllerProvider =
    Provider<PresenceHeartbeatController>((ref) {
  final controller = PresenceHeartbeatController(ref);
  ref.onDispose(controller.stop);
  return controller;
});
