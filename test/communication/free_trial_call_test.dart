import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/features/communication/services/communication_firestore_service.dart';
import 'package:college_reality_india/features/communication/services/free_trial_call_service.dart';
import 'package:college_reality_india/features/communication/utils/call_countdown.dart';
import 'package:college_reality_india/features/communication/widgets/free_call_limit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocRef extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocSnap extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  group('FreeTrialCallService.dayKeyFor (must match server dayKeyFor)', () {
    test('rolls over at IST midnight, not UTC or device midnight', () {
      expect(
        FreeTrialCallService.dayKeyFor(DateTime.utc(2026, 9, 28, 18, 29, 59)),
        '2026-09-28',
      );
      expect(
        FreeTrialCallService.dayKeyFor(DateTime.utc(2026, 9, 28, 18, 30)),
        '2026-09-29',
      );
    });

    test('usage doc id is per caller, per guide, per day', () {
      expect(
        FreeTrialCallService.usageDocId('userA', 'guide1', '2026-09-28'),
        'userA_guide1_2026-09-28',
      );
    });
  });

  group('call countdown', () {
    final start = DateTime.utc(2026, 9, 28, 10);

    test('counts down from 120 using the session start time', () {
      final elapsed = callElapsedSeconds(
        startedAt: start,
        now: start.add(const Duration(seconds: 45)),
        maxSeconds: 120,
      );
      expect(elapsed, 45);
      expect(callRemainingSeconds(elapsedSeconds: elapsed, maxSeconds: 120), 75);
    });

    test('reopening the screen late does not grant extra time', () {
      final elapsed = callElapsedSeconds(
        startedAt: start,
        now: start.add(const Duration(minutes: 10)),
        maxSeconds: 120,
      );
      expect(elapsed, 120);
      expect(callRemainingSeconds(elapsedSeconds: elapsed, maxSeconds: 120), 0);
    });

    test("the other device's clock running ahead never goes negative", () {
      expect(
        callElapsedSeconds(
          startedAt: start.add(const Duration(seconds: 5)),
          now: start,
          maxSeconds: 120,
        ),
        0,
      );
    });
  });

  group('FreeTrialCallService.checkEligibility', () {
    late _MockFirestore firestore;
    late _MockDocSnap snap;
    late _MockDocRef docRef;

    setUp(() {
      firestore = _MockFirestore();
      final collection = _MockCollection();
      docRef = _MockDocRef();
      snap = _MockDocSnap();
      when(() => firestore.collection('free_call_usage')).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(docRef);
      when(() => docRef.get()).thenAnswer((_) async => snap);
    });

    FreeTrialCallService service() =>
        FreeTrialCallService(firestore: firestore, functions: _MockFunctions());

    test('reads today\'s doc for this exact (user, guide) pair', () async {
      when(() => snap.data()).thenReturn(null);
      final now = DateTime.utc(2026, 9, 28, 10);
      await service().checkEligibility(
        callerId: 'userA',
        guideId: 'guide1',
        now: now,
      );
      verify(() => firestore.collection('free_call_usage')
          .doc('userA_guide1_2026-09-28')).called(1);
    });

    test('no record today -> available', () async {
      when(() => snap.data()).thenReturn(null);
      expect(
        await service().checkEligibility(callerId: 'userA', guideId: 'guide1'),
        FreeTrialEligibility.available,
      );
    });

    test('consumed today -> usedToday', () async {
      when(() => snap.data()).thenReturn({'status': 'consumed'});
      expect(
        await service().checkEligibility(callerId: 'userA', guideId: 'guide1'),
        FreeTrialEligibility.usedToday,
      );
    });

    test('a read failure never blocks the user (server decides)', () async {
      when(() => docRef.get()).thenThrow(Exception('offline'));
      expect(
        await service().checkEligibility(callerId: 'userA', guideId: 'guide1'),
        FreeTrialEligibility.available,
      );
    });
  });

  group('FreeTrialCallService.startFreeTrialCall', () {
    late _MockFunctions functions;
    late _MockCallable callable;

    setUp(() {
      functions = _MockFunctions();
      callable = _MockCallable();
      when(() => functions.httpsCallable('startFreeTrialCall'))
          .thenReturn(callable);
    });

    FreeTrialCallService service() =>
        FreeTrialCallService(firestore: _MockFirestore(), functions: functions);

    test('returns the server-created session id', () async {
      final result = _MockCallableResult();
      when(() => result.data).thenReturn({'sessionId': 's1'});
      when(() => callable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => result);
      expect(
        await service().startFreeTrialCall(guideId: 'guide1', callType: 'voice'),
        's1',
      );
    });

    test('free call already used -> FreeTrialUsedException', () async {
      when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: 'used',
          details: {'reason': 'free_call_used'},
        ),
      );
      expect(
        () => service().startFreeTrialCall(guideId: 'guide1', callType: 'voice'),
        throwsA(isA<FreeTrialUsedException>()
            .having((e) => e.guideId, 'guideId', 'guide1')),
      );
    });

    test('other denials (still ringing, rate limit) are plain errors',
        () async {
      when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: 'ringing',
          details: {'reason': 'call_in_progress'},
        ),
      );
      expect(
        () => service().startFreeTrialCall(guideId: 'guide1', callType: 'voice'),
        throwsA(isA<CommunicationException>()),
      );
    });
  });

  testWidgets('limit popup: Recharge opens the wallet for that guide',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showFreeCallLimitDialog(
                context,
                guideId: 'guide1',
                guideName: 'Asha',
                ratePaisePerMinute: 1000,
                balancePaise: 0,
              ),
              child: const Text('call'),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.wallet,
          builder: (_, state) => Text(
            'WALLET ${state.uri.queryParameters['guideId']} '
            '${state.uri.queryParameters['rate']}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('call'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('You have used your 2-minute free call'),
      findsOneWidget,
    );
    expect(find.textContaining('₹10/min'), findsOneWidget);

    await tester.tap(find.text('Recharge'));
    await tester.pumpAndSettle();
    expect(find.text('WALLET guide1 1000'), findsOneWidget);
  });
}
