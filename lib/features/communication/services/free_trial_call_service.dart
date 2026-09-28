import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'communication_firestore_service.dart';

/// Thrown when this user already used today's 2-minute free call with
/// this guide -- the UI answers it with the "Pay Now" popup
/// (showFreeCallLimitDialog), never a plain error snackbar.
class FreeTrialUsedException implements Exception {
  final String guideId;
  final String message;

  const FreeTrialUsedException({required this.guideId, required this.message});

  @override
  String toString() => message;
}

enum FreeTrialEligibility { available, usedToday }

/// Direct guide calls: 2 minutes free, once per day per guide.
///
/// The Cloud Function `startFreeTrialCall` is the authority -- it checks
/// and reserves the quota in one transaction and is the only thing allowed
/// to create a `call_sessions` doc. [checkEligibility] is a fast advisory
/// read of the same `free_call_usage` doc so the popup can appear
/// instantly without a function round trip.
class FreeTrialCallService {
  FreeTrialCallService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestoreOverride = firestore,
        _functionsOverride = functions;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  static const _usageCollection = 'free_call_usage';
  static const _reasonFreeCallUsed = 'free_call_used';
  static const _istOffset = Duration(hours: 5, minutes: 30);

  /// `YYYY-MM-DD` of the India calendar day containing [now]. Must match
  /// `dayKeyFor` in functions/src/freeTrialCallLogic.js (IST has no DST, so
  /// a fixed offset is exact regardless of the device's timezone).
  static String dayKeyFor(DateTime now) =>
      now.toUtc().add(_istOffset).toIso8601String().substring(0, 10);

  static String usageDocId(String callerId, String guideId, String dayKey) =>
      '${callerId}_${guideId}_$dayKey';

  /// Advisory pre-check. Any failure (offline, cold cache) returns
  /// [FreeTrialEligibility.available] so the server makes the real call
  /// rather than the user being wrongly blocked.
  Future<FreeTrialEligibility> checkEligibility({
    required String callerId,
    required String guideId,
    DateTime? now,
  }) async {
    try {
      final id = usageDocId(
        callerId,
        guideId,
        dayKeyFor(now ?? DateTime.now()),
      );
      final doc = await _firestore.collection(_usageCollection).doc(id).get();
      return doc.data()?['status'] == 'consumed'
          ? FreeTrialEligibility.usedToday
          : FreeTrialEligibility.available;
    } catch (_) {
      return FreeTrialEligibility.available;
    }
  }

  /// Creates the call session server-side and returns its id. Throws
  /// [FreeTrialUsedException] when today's free call with this guide is
  /// gone, [CommunicationException] for anything else user-facing.
  Future<String> startFreeTrialCall({
    required String guideId,
    required String callType,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('startFreeTrialCall')
          .call<Map<String, dynamic>>({
        'guideId': guideId,
        'callType': callType,
      });
      return result.data['sessionId'] as String;
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] : null;
      if (e.code == 'resource-exhausted' && reason == _reasonFreeCallUsed) {
        throw FreeTrialUsedException(
          guideId: guideId,
          message: e.message ??
              'You have used your 2-minute free call for this Guide today.',
        );
      }
      throw CommunicationException(e.message ?? 'Could not start the call.');
    }
  }
}
