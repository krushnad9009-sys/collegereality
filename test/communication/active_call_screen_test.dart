import 'dart:async';

import 'package:college_reality_india/core/constants/communication_constants.dart';
import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:college_reality_india/features/communication/models/call_session_model.dart';
import 'package:college_reality_india/features/communication/providers/communication_provider.dart';
import 'package:college_reality_india/features/communication/screens/active_call_screen.dart';
import 'package:college_reality_india/features/communication/services/call_audio_session.dart';
import 'package:college_reality_india/features/communication/services/communication_firestore_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockComm extends Mock implements CommunicationFirestoreService {}

const _sid = 'call-1';

CallSessionModel _session(String status, {bool video = false}) =>
    CallSessionModel(
      id: _sid,
      callerId: 'me',
      calleeId: 'guide',
      callType: video
          ? CommunicationConstants.callTypeVideo
          : CommunicationConstants.callTypeVoice,
      status: status,
      callerAccepted: true,
      calleeAccepted: status != CommunicationConstants.callStatusRequested,
      callerAlias: 'Student',
      calleeAlias: 'G',
      maxDurationSeconds: 120,
      isFreeTrial: true,
      createdAt: DateTime(2026, 10, 6),
      startedAt: status == CommunicationConstants.callStatusActive
          ? DateTime(2026, 10, 6)
          : null,
    );

/// Previous screen ("Guide profile") with the call pushed on top, so we
/// can see the call screen leave back to it.
Future<StreamController<CallSessionModel?>> _pumpCall(
  WidgetTester tester,
  _MockComm comm,
  CallSessionModel initial,
) async {
  final sessions = StreamController<CallSessionModel?>.broadcast();
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Guide profile')),
      ),
      GoRoute(
        path: '/call',
        builder: (_, _) => const ActiveCallScreen(sessionId: _sid),
      ),
    ],
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(MockUser(uid: 'me')),
      communicationServiceProvider.overrideWithValue(comm),
      callSessionProvider(_sid).overrideWith((ref) async* {
        yield initial;
        yield* sessions.stream;
      }),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  router.push('/call');
  await tester.pumpAndSettle();
  return sessions;
}

void main() {
  late _MockComm comm;

  setUp(() {
    comm = _MockComm();
  });

  testWidgets('caller can cancel while ringing; screen goes back',
      (tester) async {
    final sessions = await _pumpCall(
      tester,
      comm,
      _session(CommunicationConstants.callStatusRequested),
    );
    when(() => comm.endCall(
          sessionId: _sid,
          userId: 'me',
          emergency: false,
        )).thenAnswer((_) async {
      sessions.add(_session(CommunicationConstants.callStatusEnded));
    });

    expect(find.text('Cancel call'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pump();
    verify(() => comm.endCall(sessionId: _sid, userId: 'me', emergency: false))
        .called(1);

    // Never-connected call: no rating sheet, brief "Call ended", then back.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('Guide profile'), findsOneWidget);
    expect(find.byType(ActiveCallScreen), findsNothing);
    await sessions.close();
  });

  testWidgets('End call + Speaker are visible on a small phone (video call)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final sessions = await _pumpCall(
      tester,
      comm,
      _session(CommunicationConstants.callStatusActive, video: true),
    );

    for (final label in ['End call', 'Speaker', 'Mute', 'Emergency']) {
      expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);
    await sessions.close();
  });

  testWidgets('End call during a live call ends it and leaves even if the '
      'network write fails', (tester) async {
    final sessions = await _pumpCall(
      tester,
      comm,
      _session(CommunicationConstants.callStatusActive),
    );
    when(() => comm.endCall(
          sessionId: _sid,
          userId: 'me',
          emergency: false,
        )).thenThrow(CommunicationException('offline'));

    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();
    expect(find.text('Guide profile'), findsOneWidget);
    await sessions.close();
  });

  test('call audio starts on the earpiece', () {
    final audio = CallAudioSession(sessionId: 'x');
    expect(audio.state.value.speakerOn, isFalse);
  });
}
