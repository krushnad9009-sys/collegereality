import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/firestore_constants.dart';
import '../models/payout_models.dart';

/// Reads the backend-authoritative `guide_earnings` ledger and manages the
/// client-writable `payout_requests` collection layered on top of it (see
/// firestore.rules for exactly what each side may write). Deliberately
/// never writes to `guide_earnings` itself -- that stays Cloud-Function-only.
///
/// Every READ method below is best-effort: a transient Firestore hiccup, a
/// composite index still building, or one malformed document should never
/// take down the whole admin dashboard or a guide's own earnings screen --
/// see the doc comments on each method for what it degrades to. Write
/// methods (create/approve/reject) deliberately do NOT swallow errors --
/// those are user-initiated actions the caller must be able to report as
/// failed.
class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _payoutRequests =>
      _firestore.collection(FirestoreConstants.payoutRequestsCollection);

  CollectionReference<Map<String, dynamic>> _guideEarningsEntries(String guideId) =>
      _firestore
          .collection('guide_earnings')
          .doc(guideId)
          .collection('entries');

  void _logFetchFailure(String label, Object e) {
    if (kDebugMode) debugPrint('[PayoutService] $label failed: $e');
  }

  /// This guide's own earnings ledger, newest first. Bounded to 500 --
  /// generous for an individual guide's history without risking an
  /// unbounded read. Returns an empty list (never throws) on failure --
  /// callers render that as "no sessions yet" rather than an error screen.
  Future<List<GuideEarningsEntry>> fetchGuideEarningsEntries(String guideId) async {
    try {
      final snap = await _guideEarningsEntries(guideId)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();
      return snap.docs
          .map((d) => _parseEntry(d, guideId: guideId))
          .whereType<GuideEarningsEntry>()
          .toList();
    } catch (e) {
      _logFetchFailure('fetchGuideEarningsEntries($guideId)', e);
      return const [];
    }
  }

  /// Every 'payable' entry across every guide in one bounded query, used by
  /// the admin directory to compute each guide's total earned + completed
  /// count without an N+1 per-guide read. Same "aggregate client-side from
  /// one bounded collection(-group) query" convention already used by
  /// AdminConsultationRevenueScreen for the payments collection. The
  /// guideId for each entry is its doc's grandparent id
  /// (`guide_earnings/{guideId}/entries/{entryId}`). Returns an empty list
  /// (never throws) on failure -- the admin dashboard then shows ₹0 totals
  /// instead of an error screen.
  Future<List<GuideEarningsEntry>> fetchAllPayableEntries({int limit = 5000}) async {
    try {
      final snap = await _firestore
          .collectionGroup('entries')
          .where('status', isEqualTo: 'payable')
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => _parseEntry(d, guideId: d.reference.parent.parent?.id ?? ''))
          .whereType<GuideEarningsEntry>()
          .toList();
    } catch (e) {
      _logFetchFailure('fetchAllPayableEntries', e);
      return const [];
    }
  }

  /// Parses one `guide_earnings/.../entries` doc, or `null` on a malformed
  /// document (e.g. a legacy shape) -- one bad row must never take down an
  /// aggregate query spanning every guide.
  GuideEarningsEntry? _parseEntry(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    String? guideId,
  }) {
    try {
      return GuideEarningsEntry.fromJson(
        doc.data(),
        docId: doc.id,
        guideId: guideId ?? doc.reference.parent.parent?.id ?? '',
      );
    } catch (e) {
      _logFetchFailure('parse entry ${doc.reference.path}', e);
      return null;
    }
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

  /// Returns an empty list (never throws) on failure -- the guide's own
  /// Earnings screen renders that as "no withdrawal requests yet".
  Future<List<PayoutRequestModel>> fetchGuidePayoutRequests(String guideId) async {
    try {
      final snap = await _payoutRequests
          .where('guideId', isEqualTo: guideId)
          .orderBy('requestedAt', descending: true)
          .limit(200)
          .get();
      return snap.docs
          .map((d) => _parseRequest(d))
          .whereType<PayoutRequestModel>()
          .toList();
    } catch (e) {
      _logFetchFailure('fetchGuidePayoutRequests($guideId)', e);
      return const [];
    }
  }

  /// Returns an empty list (never throws) on failure -- the admin dashboard
  /// then shows "0 pending requests" / an empty-state card instead of an
  /// error screen.
  Future<List<PayoutRequestModel>> fetchPayoutRequestsByStatus(
    String status, {
    int limit = 500,
  }) async {
    try {
      final snap = await _payoutRequests
          .where('status', isEqualTo: status)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => _parseRequest(d))
          .whereType<PayoutRequestModel>()
          .toList();
    } catch (e) {
      _logFetchFailure('fetchPayoutRequestsByStatus($status)', e);
      return const [];
    }
  }

  /// Every payout request regardless of status, newest first -- used by the
  /// admin dashboard to derive the pending queue, the period-filtered
  /// "paid" totals, and the CSV export in one read instead of one query per
  /// status. Returns an empty list (never throws) on failure.
  Future<List<PayoutRequestModel>> fetchAllPayoutRequests({int limit = 2000}) async {
    try {
      final snap = await _payoutRequests
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => _parseRequest(d))
          .whereType<PayoutRequestModel>()
          .toList();
    } catch (e) {
      _logFetchFailure('fetchAllPayoutRequests', e);
      return const [];
    }
  }

  /// Parses one `payout_requests` doc, or `null` on a malformed document --
  /// one bad row must never take down the whole pending-requests queue.
  PayoutRequestModel? _parseRequest(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return PayoutRequestModel.fromJson(doc.data(), docId: doc.id);
    } catch (e) {
      _logFetchFailure('parse request ${doc.reference.path}', e);
      return null;
    }
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
