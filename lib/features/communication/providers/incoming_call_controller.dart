import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/communication_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../engagement/services/local_notification_service.dart';
import '../models/call_session_model.dart';
import '../utils/communication_formatters.dart';

/// Ignore "requested" calls older than this -- leftovers the server sweeper
/// hasn't marked missed yet. Deliberately generous (the sweeper already
/// ends unanswered calls after 60s): comparing a server-written createdAt
/// with this device's clock must not silently drop a live call when the
/// phone's clock runs a minute or two fast.
const Duration incomingCallMaxAge = Duration(minutes: 3);

/// Pure: which of [incoming] should start ringing now.
List<CallSessionModel> callsToRing(
  List<CallSessionModel> incoming, {
  required Set<String> alreadyHandled,
  required DateTime now,
}) {
  return incoming
      .where((c) =>
          c.status == CommunicationConstants.callStatusRequested &&
          !alreadyHandled.contains(c.id) &&
          now.difference(c.createdAt) < incomingCallMaxAge)
      .toList();
}

/// Call screens currently on screen, so a notification tap and this
/// controller never open the same call twice (two screens would each try
/// to join the audio channel).
class OpenCallScreens {
  OpenCallScreens._();
  static final Set<String> ids = <String>{};
}

/// Rings and opens the incoming-call screen whenever someone calls this
/// user while the app is running -- on ANY screen. Previously the only
/// in-app signal was a banner that exists solely on Home, so a guide on
/// any other screen never saw the call.
///
/// Driven by the live call_sessions stream (not the FCM push), so it still
/// works when a push is late or dropped. Pushes cover the app-closed case
/// (firebaseMessagingBackgroundHandler). Started by AppShell; idempotent.
class IncomingCallController {
  IncomingCallController(
    this._ref, {
    Stream<List<CallSessionModel>> Function(String uid)? watchIncoming,
    LocalNotificationService? notifications,
  })  : _watchIncoming = watchIncoming ??
            ((uid) => FirebaseFirestore.instance.watchIncomingCalls(uid)),
        _notifications = notifications ?? LocalNotificationService.instance;

  final Ref _ref;
  final Stream<List<CallSessionModel>> Function(String uid) _watchIncoming;
  final LocalNotificationService _notifications;

  StreamSubscription<List<CallSessionModel>>? _sub;
  String? _uid;
  GoRouter? _router;
  final Set<String> _handled = <String>{};
  final Set<String> _ringing = <String>{};

  void start({required GoRouter router}) {
    _router = router;
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    if (_uid == uid && _sub != null) return;
    stop();
    _uid = uid;
    _sub = _watchIncoming(uid).listen(
      onCalls,
      onError: (Object e) => debugPrint('[IncomingCall] stream error: $e'),
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    for (final id in _ringing) {
      unawaited(_notifications.cancelIncomingCall(id));
    }
    _ringing.clear();
    _handled.clear();
  }

  @visibleForTesting
  void onCalls(List<CallSessionModel> calls) {
    // Stop ringing for calls that were answered, declined or missed.
    final stillRequested = calls
        .where((c) => c.status == CommunicationConstants.callStatusRequested)
        .map((c) => c.id)
        .toSet();
    for (final id in _ringing.difference(stillRequested).toList()) {
      _ringing.remove(id);
      unawaited(_notifications.cancelIncomingCall(id));
    }

    for (final call in callsToRing(
      calls,
      alreadyHandled: _handled,
      now: DateTime.now(),
    )) {
      _handled.add(call.id);
      _ringing.add(call.id);
      final path = RouteNames.activeCallPath(call.id);
      unawaited(_notifications.showIncomingCall(
        sessionId: call.id,
        title: 'Incoming ${call.isVideo ? 'video' : 'voice'} call',
        body: '${call.callerAlias} is calling you',
        payload: path,
      ));
      _openCallScreen(call.id, path);
    }
  }

  void _openCallScreen(String sessionId, String path) {
    final router = _router;
    if (router == null) return;
    // After the current frame, so a notification tap that is navigating
    // to this same call right now has registered its screen first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (OpenCallScreens.ids.contains(sessionId)) return;
      router.push(path);
    });
  }
}

final incomingCallControllerProvider = Provider<IncomingCallController>((ref) {
  final controller = IncomingCallController(ref);
  ref.onDispose(controller.stop);
  return controller;
});
