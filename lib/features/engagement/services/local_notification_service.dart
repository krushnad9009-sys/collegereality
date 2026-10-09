import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows OS-level notifications when FCM messages arrive or in-app events fire.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Where a tapped notification's payload (an in-app route) goes. Set by
  /// FirebaseMessagingService once the router exists. A tap that lands
  /// before that (cold start from a notification) is held in
  /// [_pendingRoute] and delivered as soon as a handler is set.
  void Function(String route)? _onRouteTap;
  String? _pendingRoute;

  set onRouteTap(void Function(String route)? handler) {
    _onRouteTap = handler;
    final pending = _pendingRoute;
    if (handler != null && pending != null) {
      _pendingRoute = null;
      handler(pending);
    }
  }

  // Android: FLAG_INSISTENT -- repeat the sound until the notification is
  // answered or cancelled, like a phone ringing (not a single chime).
  static const int _flagInsistent = 4;
  static const Duration _ringTimeout = Duration(seconds: 60);

  static const _callChannelId = 'incoming_calls';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      // Without this, tapping a notification just opened the app wherever
      // it was -- an incoming call's /call/<id> payload was ignored.
      onDidReceiveNotificationResponse: (response) =>
          _deliverRoute(response.payload),
    );

    // App cold-started by tapping one of our notifications.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _deliverRoute(launch!.notificationResponse?.payload);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  void _deliverRoute(String? route) {
    if (route == null || route.isEmpty) return;
    final handler = _onRouteTap;
    if (handler == null) {
      _pendingRoute = route;
    } else {
      handler(route);
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'college_reality_alerts',
        'College Kundli Alerts',
        channelDescription: 'Notifications for answers, chat, and updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Stable notification id per call, so the ring can be cancelled later.
  static int incomingCallNotificationId(String sessionId) =>
      sessionId.hashCode & 0x7fffffff;

  /// A ringing incoming-call notification: its own max-importance channel,
  /// ringtone audio stream, repeating sound, full-screen on a locked
  /// screen (Android), auto-stops after [_ringTimeout]. Tapping it opens
  /// the call screen ([payload] = `/call/<id>`).
  Future<void> showIncomingCall({
    required String sessionId,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;
    await initialize();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _callChannelId,
        'Incoming calls',
        channelDescription: 'Rings for incoming voice calls',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        additionalFlags: Int32List.fromList(const [_flagInsistent]),
        ongoing: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
        timeoutAfter: _ringTimeout.inMilliseconds,
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    await _plugin.show(
      incomingCallNotificationId(sessionId),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Stops the ring for [sessionId] (answered, declined, missed, ended).
  Future<void> cancelIncomingCall(String sessionId) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(incomingCallNotificationId(sessionId));
  }
}
