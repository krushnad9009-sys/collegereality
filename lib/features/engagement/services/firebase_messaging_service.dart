import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../core/bootstrap/firebase_bootstrap.dart';
import '../../../core/constants/firestore_constants.dart';
import 'firestore_engagement_service.dart';
import 'local_notification_service.dart';

/// Top-level background handler required by FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  final userId = data['userId'] as String?;
  if (userId == null || userId.isEmpty) return;

  final title = message.notification?.title ?? data['title'] as String? ?? 'College Reality';
  final body = message.notification?.body ?? data['body'] as String? ?? '';
  final type = data['type'] as String? ?? 'general';
  final category = data['category'] as String? ?? '';
  final entityType = data['entityType'] as String? ?? '';
  final entityId = data['entityId'] as String? ?? '';
  final actionRoute = data['actionRoute'] as String? ?? '';

  final firestore = FirebaseFirestore.instance;
  final dedupeId = '${userId}_${type}_$entityId';
  final existing = await firestore
      .collection(FirestoreConstants.userNotificationsCollection)
      .doc(dedupeId)
      .get();
  if (existing.exists) return;

  await firestore
      .collection(FirestoreConstants.userNotificationsCollection)
      .doc(dedupeId)
      .set({
    'id': dedupeId,
    'userId': userId,
    'type': type,
    'category': category,
    'title': title,
    'body': body,
    'entityType': entityType,
    'entityId': entityId,
    'actionRoute': actionRoute,
    'isRead': false,
    'createdAt': DateTime.now().toIso8601String(),
  });

  await LocalNotificationService.instance.show(
    id: dedupeId.hashCode,
    title: title,
    body: body,
    payload: actionRoute,
  );
}

class FirebaseMessagingService {
  FirebaseMessagingService(this._engagementService);

  final FirestoreEngagementService _engagementService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _currentUserId;
  GoRouter? _router;

  Future<void> initialize({
    required String userId,
    GoRouter? router,
  }) async {
    if (_initialized && _currentUserId == userId) return;
    await FirebaseBootstrap.ensureInitialized();
    await LocalNotificationService.instance.initialize();

    _currentUserId = userId;
    _router = router;

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
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _navigateFromMessage(initial);
    }

    _initialized = true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final userId = _currentUserId;
    if (userId == null) return;

    final data = message.data;
    final type = data['type'] as String? ?? 'general';
    final category = data['category'] as String? ?? '';
    final title =
        message.notification?.title ?? data['title'] as String? ?? 'Notification';
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

    unawaited(
      LocalNotificationService.instance.show(
        id: title.hashCode ^ body.hashCode,
        title: title,
        body: body,
        payload: actionRoute,
      ),
    );
  }

  void _handleMessageOpened(RemoteMessage message) {
    _navigateFromMessage(message);
  }

  void _navigateFromMessage(RemoteMessage message) {
    final route = message.data['actionRoute'] as String? ?? '';
    if (route.isEmpty) return;
    final router = _router;
    if (router == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(route.isNotEmpty ? route : RouteNames.notifications);
    });
  }

  Future<void> dispose() async {
    _initialized = false;
    _currentUserId = null;
    _router = null;
  }
}
