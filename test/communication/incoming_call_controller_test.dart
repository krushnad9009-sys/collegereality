import 'package:college_reality_india/core/constants/communication_constants.dart';
import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:college_reality_india/features/communication/models/call_session_model.dart';
import 'package:college_reality_india/features/communication/providers/incoming_call_controller.dart';
import 'package:college_reality_india/features/engagement/services/local_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotifications extends Mock implements LocalNotificationService {}

class _MockUser extends Mock implements User {}

CallSessionModel _call(
  String id, {
  String status = CommunicationConstants.callStatusRequested,
  Duration age = const Duration(seconds: 5),
}) =>
    CallSessionModel(
      id: id,
      callerId: 'student',
      calleeId: 'guide',
      callType: CommunicationConstants.callTypeVoice,
      status: status,
      callerAlias: 'Student #1',
      calleeAlias: 'Guide #2',
      maxDurationSeconds: 120,
      createdAt: DateTime.now().subtract(age),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('callsToRing', () {
    final now = DateTime.now();

    test('rings a fresh requested call once', () {
      expect(callsToRing([_call('a')], alreadyHandled: {}, now: now), hasLength(1));
      expect(callsToRing([_call('a')], alreadyHandled: {'a'}, now: now), isEmpty);
    });

    test('never rings calls that are already answered or over', () {
      for (final status in [
        CommunicationConstants.callStatusActive,
        CommunicationConstants.callStatusAccepted,
        CommunicationConstants.callStatusMissed,
      ]) {
        expect(
          callsToRing([_call('a', status: status)], alreadyHandled: {}, now: now),
          isEmpty,
        );
      }
    });

    test('ignores stale leftovers but tolerates a fast device clock', () {
      expect(
        callsToRing([_call('old', age: const Duration(minutes: 10))],
            alreadyHandled: {}, now: now),
        isEmpty,
      );
      // Device clock 2 minutes ahead of the server: still rings.
      expect(
        callsToRing([_call('a', age: const Duration(minutes: 2))],
            alreadyHandled: {}, now: now),
        hasLength(1),
      );
    });
  });

  group('IncomingCallController.onCalls', () {
    late _MockNotifications notifications;
    late IncomingCallController controller;
    late ProviderContainer container;

    setUp(() {
      notifications = _MockNotifications();
      when(() => notifications.showIncomingCall(
            sessionId: any(named: 'sessionId'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});
      when(() => notifications.cancelIncomingCall(any()))
          .thenAnswer((_) async {});
      final user = _MockUser();
      when(() => user.uid).thenReturn('guide');
      container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(user),
        incomingCallControllerProvider.overrideWith(
          (ref) => IncomingCallController(ref, notifications: notifications),
        ),
      ]);
      controller = container.read(incomingCallControllerProvider);
    });

    tearDown(() => container.dispose());

    test('rings a new call with the call-screen route as payload', () {
      controller.onCalls([_call('s1')]);
      verify(() => notifications.showIncomingCall(
            sessionId: 's1',
            title: 'Incoming voice call',
            body: 'Student #1 is calling you',
            payload: '/call/s1',
          )).called(1);
    });

    test('does not ring the same call twice on later snapshots', () {
      controller.onCalls([_call('s1')]);
      controller.onCalls([_call('s1')]);
      verify(() => notifications.showIncomingCall(
            sessionId: 's1',
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('stops ringing once the call is answered, declined or missed', () {
      controller.onCalls([_call('s1')]);
      controller.onCalls(const []); // left the requested set
      verify(() => notifications.cancelIncomingCall('s1')).called(1);
    });
  });
}
