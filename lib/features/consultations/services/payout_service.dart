import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../models/payout_models.dart';

/// Reads the backend-authoritative `guide_earnings` ledger and manages the
/// client-writable `payout_requests` collection layered on top of it (see
/// firestore.rules for exactly what each side may write). Deliberately
/// never writes to `guide_earnings` itself -- that stays Cloud-Function-only.
class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _payoutRequests =>
      _firestore.collection(FirestoreConstants.payoutRequestsCollection);

  CollectionReference<Map<String, dynamic>> _guideEarningsEntries(String guideId) =>
      _firestore
          .collection('guide_earnings')
          .doc(guideId)
          .collection('entries');

  /// This guide's own earnings ledger, newest first. Bounded to 500 --
  /// generous for an individual guide's history without risking an
  /// unbounded read.
  Future<List<GuideEarningsEntry>> fetchGuideEarningsEntries(String guideId) async {
    final snap = await _guideEarningsEntries(guideId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    return snap.docs
        .map((d) => GuideEarningsEntry.fromJson(d.data(), docId: d.id, guideId: guideId))
        .toList();
  }

  /// Every 'payable' entry across every guide in one bounded query, used by
  /// the admin directory to compute each guide's total earned + completed
  /// count without an N+1 per-guide read. Same "aggregate client-side from
  /// one bounded collection(-group) query" convention already used by
  /// AdminConsultationRevenueScreen for the payments collection. The
  /// guideId for each entry is its doc's grandparent id
  /// (`guide_earnings/{guideId}/entries/{entryId}`).
  Future<List<GuideEarningsEntry>> fetchAllPayableEntries({int limit = 5000}) async {
    final snap = await _firestore
        .collectionGroup('entries')
        .where('status', isEqualTo: 'payable')
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => GuideEarningsEntry.fromJson(
              d.data(),
              docId: d.id,
              guideId: d.reference.parent.parent?.id ?? '',
            ))
        .toList();
  }

  Future<PayoutRequestModel> createPayoutRequest({
    required String guideId,
    required String guideName,
    required int amountPaise,
    required PayoutMethodSnapshot payoutMethod,
  }) async {
    final now = DateTime.now();
    final data = <String, dynamic>{
      'guideId': guideId,
      'guideName': guideName,
      'amountPaise': amountPaise,
      'payoutMethod': payoutMethod.toJson(),
      'status': PayoutRequestConstants.statusPending,
      'requestedAt': now.toIso8601String(),
      'decidedAt': null,
      'decidedBy': null,
      'transactionId': null,
      'rejectionReason': null,
    };
    final ref = await _payoutRequests.add(data);
    return PayoutRequestModel.fromJson(data, docId: ref.id);
  }

  Future<List<PayoutRequestModel>> fetchGuidePayoutRequests(String guideId) async {
    final snap = await _payoutRequests
        .where('guideId', isEqualTo: guideId)
        .orderBy('requestedAt', descending: true)
        .limit(200)
        .get();
    return snap.docs
        .map((d) => PayoutRequestModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<List<PayoutRequestModel>> fetchPayoutRequestsByStatus(
    String status, {
    int limit = 500,
  }) async {
    final snap = await _payoutRequests
        .where('status', isEqualTo: status)
        .orderBy('requestedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => PayoutRequestModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> approvePayoutRequest({
    required String requestId,
    required String transactionId,
    required String adminUid,
  }) async {
    await _payoutRequests.doc(requestId).update({
      'status': PayoutRequestConstants.statusPaid,
      'transactionId': transactionId,
      'decidedAt': DateTime.now().toIso8601String(),
      'decidedBy': adminUid,
    });
  }

  Future<void> rejectPayoutRequest({
    required String requestId,
    required String reason,
    required String adminUid,
  }) async {
    await _payoutRequests.doc(requestId).update({
      'status': PayoutRequestConstants.statusRejected,
      'rejectionReason': reason,
      'decidedAt': DateTime.now().toIso8601String(),
      'decidedBy': adminUid,
    });
  }
}
