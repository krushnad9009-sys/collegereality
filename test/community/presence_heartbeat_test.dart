import 'package:college_reality_india/core/constants/consultation_constants.dart';
import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:college_reality_india/features/community/models/user_presence_model.dart';
import 'package:college_reality_india/features/community/providers/community_provider.dart';
import 'package:college_reality_india/features/community/providers/presence_heartbeat_provider.dart';
import 'package:college_reality_india/features/community/services/community_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockService extends Mock implements CommunityFirestoreService {}

class _MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PresenceHeartbeatController lifecycle', () {
    late _MockService service;
    late ProviderContainer container;
    late PresenceHeartbeatController controller;

    setUp(() {
      service = _MockService();
      when(() => service.updatePresence(any(), isOnline: any(named: 'isOnline')))
          .thenAnswer((_) async {});
      final user = _MockUser();
      when(() => user.uid).thenReturn('u1');
      container = ProviderContainer(overrides: [
        communityServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWithValue(user),
      ]);
      controller = container.read(presenceHeartbeatControllerProvider);
    });

    tearDown(() => container.dispose());

    test('start marks online', () {
      controller.start();
      verify(() => service.updatePresence('u1', isOnline: true)).called(1);
    });

    test('paused marks offline once, even if hidden fired first', () {
      controller.start();
      clearInteractions(service);
      controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      verify(() => service.updatePresence('u1', isOnline: false)).called(1);
      verifyNoMoreInteractions(service);
    });

    test('inactive is ignored (transient overlays must not flap presence)', () {
      controller.start();
      clearInteractions(service);
      controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      verifyNoMoreInteractions(service);
    });

    test('resumed after background marks online again', () {
      controller.start();
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      clearInteractions(service);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      verify(() => service.updatePresence('u1', isOnline: true)).called(1);
    });

    test('markOfflineAndStop writes offline and detaches the observer',
        () async {
      controller.start();
      await controller.markOfflineAndStop();
      verify(() => service.updatePresence('u1', isOnline: false)).called(1);
      clearInteractions(service);
      // No longer observing: a later resume must not re-mark online.
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      verifyNoMoreInteractions(service);
    });
  });

  group('UserPresenceModel.isActiveNow', () {
    test('online + fresh heartbeat is active', () {
      final p = UserPresenceModel(isOnline: true, lastSeenAt: DateTime.now());
      expect(p.isActiveNow, isTrue);
    });

    test('online flag with a stale heartbeat (force-quit app) is not active',
        () {
      final p = UserPresenceModel(
        isOnline: true,
        lastSeenAt: DateTime.now().subtract(
          ConsultationConstants.presenceStaleAfter + const Duration(seconds: 1),
        ),
      );
      expect(p.isActiveNow, isFalse);
    });

    test('explicitly offline is not active even if just seen', () {
      final p = UserPresenceModel(isOnline: false, lastSeenAt: DateTime.now());
      expect(p.isActiveNow, isFalse);
    });
  });
}
