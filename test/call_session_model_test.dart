import 'package:college_reality_india/core/constants/communication_constants.dart';
import 'package:college_reality_india/features/communication/models/call_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

CallSessionModel _session({
  String id = 'call-1',
  String callerId = 'caller-1',
  String calleeId = 'callee-1',
  String callType = CommunicationConstants.callTypeVoice,
  bool callerAccepted = false,
  bool calleeAccepted = false,
}) {
  return CallSessionModel(
    id: id,
    callerId: callerId,
    calleeId: calleeId,
    callType: callType,
    status: CommunicationConstants.callStatusRequested,
    callerAlias: 'Guide #111',
    calleeAlias: 'Guide #222',
    callerTier: CommunicationConstants.subscriptionBronze,
    calleeTier: CommunicationConstants.subscriptionFree,
    maxDurationSeconds: 600,
    createdAt: DateTime(2026, 3, 1, 14, 0),
  ).copyWith(
    callerAccepted: callerAccepted,
    calleeAccepted: calleeAccepted,
  );
}

void main() {
  group('CallSessionModel helpers', () {
    test('isVideo detects video call type', () {
      expect(_session(callType: CommunicationConstants.callTypeVideo).isVideo, isTrue);
      expect(_session(callType: CommunicationConstants.callTypeVoice).isVideo, isFalse);
    });

    test('bothAccepted requires caller and callee acceptance', () {
      expect(_session().bothAccepted, isFalse);
      expect(_session(callerAccepted: true, calleeAccepted: true).bothAccepted, isTrue);
    });

    test('isParticipant identifies caller and callee', () {
      final session = _session();
      expect(session.isParticipant('caller-1'), isTrue);
      expect(session.isParticipant('callee-1'), isTrue);
      expect(session.isParticipant('other'), isFalse);
    });

    test('peerIdFor and peerAliasFor return opposite party', () {
      final session = _session();
      expect(session.peerIdFor('caller-1'), 'callee-1');
      expect(session.peerAliasFor('caller-1'), 'Guide #222');
      expect(session.peerIdFor('callee-1'), 'caller-1');
      expect(session.peerAliasFor('callee-1'), 'Guide #111');
    });
  });

  group('CallSessionModel JSON', () {
    test('toJson includes core session fields', () {
      final json = _session().toJson();
      expect(json['id'], 'call-1');
      expect(json['callerId'], 'caller-1');
      expect(json['callType'], CommunicationConstants.callTypeVoice);
      expect(json['maxDurationSeconds'], 600);
      expect(json['callerTier'], CommunicationConstants.subscriptionBronze);
    });

    test('fromJson round-trip preserves data', () {
      final original = _session(
        callerAccepted: true,
        calleeAccepted: true,
      ).copyWith(
        status: CommunicationConstants.callStatusActive,
        startedAt: DateTime(2026, 3, 1, 14, 5),
        endedAt: DateTime(2026, 3, 1, 14, 15),
        endedBy: 'caller-1',
        isEmergencyEnd: false,
        ratingsSubmittedCaller: true,
      );

      final restored = CallSessionModel.fromJson(original.toJson(), docId: 'call-1');
      expect(restored.id, 'call-1');
      expect(restored.callerAccepted, isTrue);
      expect(restored.calleeAccepted, isTrue);
      expect(restored.status, CommunicationConstants.callStatusActive);
      expect(restored.startedAt, isNotNull);
      expect(restored.ratingsSubmittedCaller, isTrue);
    });

    test('fromJson applies defaults for missing fields', () {
      final session = CallSessionModel.fromJson({
        'callerId': 'a',
        'calleeId': 'b',
        'createdAt': '2026-01-01T00:00:00.000',
      });
      expect(session.callType, CommunicationConstants.callTypeVoice);
      expect(session.status, CommunicationConstants.callStatusRequested);
      expect(session.maxDurationSeconds, 300);
      expect(session.callerAlias, 'Guide');
    });
  });

  group('CallSessionModel.copyWith', () {
    test('updates session lifecycle fields', () {
      final updated = _session().copyWith(
        status: CommunicationConstants.callStatusActive,
        callerAccepted: true,
        calleeAccepted: true,
        startedAt: DateTime(2026, 3, 1, 14, 1),
        ratingsSubmittedCaller: true,
        ratingsSubmittedCallee: true,
      );

      expect(updated.status, CommunicationConstants.callStatusActive);
      expect(updated.bothAccepted, isTrue);
      expect(updated.startedAt, isNotNull);
      expect(updated.ratingsSubmittedCaller, isTrue);
      expect(updated.ratingsSubmittedCallee, isTrue);
      expect(updated.callerId, 'caller-1');
    });
  });
}
