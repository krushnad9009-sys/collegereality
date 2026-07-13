import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/bootstrap/firebase_bootstrap.dart';
import 'firestore_engagement_service.dart';

/// Top-level background handler required by FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseMessagingService {
  FirebaseMessagingService(this._engagementService);

  final FirestoreEngagementService _engagementService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _currentUserId;

  Future<void> initialize({required String userId}) async {
    if (_initialized && _currentUserId == userId) return;
    await FirebaseBootstrap.ensureInitialized();

    _currentUserId = userId;

    if (!kIsWeb) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _engagementService.saveFcmToken(userId, token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      if (_currentUserId != null) {
        await _engagementService.saveFcmToken(_currentUserId!, newToken);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _initialized = true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final userId = _currentUserId;
    if (userId == null) return;

    final data = message.data;
    final type = data['type'] as String? ?? 'general';
    final category = data['category'] as String? ?? '';
    final title = message.notification?.title ?? data['title'] as String? ?? 'Notification';
    final body = message.notification?.body ?? data['body'] as String? ?? '';
    final entityType = data['entityType'] as String? ?? '';
    final entityId = data['entityId'] as String? ?? '';
    final actionRoute = data['actionRoute'] as String? ?? '';

    unawaited(
      _engagementService.notifyUser(
        userId: userId,
        type: type,
        category: category,
        title: title,
        body: body,
        entityType: entityType,
        entityId: entityId,
        actionRoute: actionRoute,
      ),
    );
  }

  Future<void> dispose() async {
    _initialized = false;
    _currentUserId = null;
  }
}
