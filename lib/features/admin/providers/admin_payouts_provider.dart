import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../auth/models/user_model.dart';
import '../../consultations/models/payout_models.dart';
import '../../consultations/providers/consultation_provider.dart';

class AdminGuideSummary {
  final UserModel user;
  final int completedConsultations;
  final int totalEarnedPaise;
  final int availableBalancePaise;

  const AdminGuideSummary({
    required this.user,
    required this.completedConsultations,
    required this.totalEarnedPaise,
    required this.availableBalancePaise,
  });
}

class AdminRevenueSummary {
  final int grossPaise;
  final int commissionPaise;
  final int guidePayoutEarnedPaise;

  const AdminRevenueSummary({
    this.grossPaise = 0,
    this.commissionPaise = 0,
    this.guidePayoutEarnedPaise = 0,
  });
}

class AdminPayoutsDashboard {
  final AdminRevenueSummary revenue;
  final List<PayoutRequestModel> pendingRequests;
  final int totalPaidOutPaise;
  final int paidRequestCount;
  final List<AdminGuideSummary> guides;

  const AdminPayoutsDashboard({
    required this.revenue,
    required this.pendingRequests,
    required this.totalPaidOutPaise,
    required this.paidRequestCount,
    required this.guides,
  });
}

/// Everything the Super Admin Payouts panel needs, assembled from a small
/// number of bounded queries run concurrently and joined client-side --
/// the same convention AdminConsultationRevenueScreen already uses for the
/// `payments` collection, extended here across `payments`,
/// `payout_requests`, `users`, and the `guide_earnings` collection group.
final adminPayoutsDashboardProvider =
    FutureProvider.autoDispose<AdminPayoutsDashboard>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final payoutService = ref.watch(payoutServiceProvider);

  // Fire all five queries before awaiting any of them, so they run
  // concurrently rather than one after another.
  final paymentsFuture = firestore
      .collection(FirestoreConstants.paymentsCollection)
      .where('status', whereIn: ['success', 'refunded'])
      .limit(1000)
      .get();
  final pendingFuture = payoutService.fetchPayoutRequestsByStatus(
    PayoutRequestConstants.statusPending,
    limit: 500,
  );
  final paidFuture = payoutService.fetchPayoutRequestsByStatus(
    PayoutRequestConstants.statusPaid,
    limit: 1000,
  );
  final entriesFuture = payoutService.fetchAllPayableEntries(limit: 5000);
  final guidesFuture = firestore
      .collection(FirestoreConstants.usersCollection)
      .where('communicationSettings.isGuideAvailable', isEqualTo: true)
      .limit(300)
      .get();

  final paymentsSnap = await paymentsFuture;
  final pendingRequests = await pendingFuture;
  final paidRequests = await paidFuture;
  final payableEntries = await entriesFuture;
  final guidesSnap = await guidesFuture;

  var gross = 0, commission = 0, guideEarned = 0;
  for (final doc in paymentsSnap.docs) {
    final data = doc.data();
    gross += ((data['grossAmountPaise'] as num?) ?? 0).toInt();
    commission += ((data['platformFeePaise'] as num?) ?? 0).toInt();
    guideEarned += ((data['guideAmountPaise'] as num?) ?? 0).toInt();
  }

  final totalPaidOutPaise =
      paidRequests.fold<int>(0, (t, r) => t + r.amountPaise);

  // Per-guide totals from the one bounded `payable` entries query, and
  // per-guide reserved (pending + already-paid request) amounts from the
  // two payout_requests queries above -- avoids an N+1 read per guide.
  final earnedByGuide = <String, int>{};
  final countByGuide = <String, int>{};
  for (final e in payableEntries) {
    earnedByGuide[e.guideId] = (earnedByGuide[e.guideId] ?? 0) + e.amountPaise;
    countByGuide[e.guideId] = (countByGuide[e.guideId] ?? 0) + 1;
  }
  final reservedByGuide = <String, int>{};
  for (final r in [...pendingRequests, ...paidRequests]) {
    reservedByGuide[r.guideId] = (reservedByGuide[r.guideId] ?? 0) + r.amountPaise;
  }

  final guides = guidesSnap.docs.map((doc) {
    final user = UserModel.fromJson(doc.data(), docId: doc.id);
    final earned = earnedByGuide[user.uid] ?? 0;
    final manualAdjustment = ((user.metadata?['wallet'] as Map?)
                ?['manualAdjustmentPaise'] as num?)
            ?.toInt() ??
        0;
    final reserved = reservedByGuide[user.uid] ?? 0;
    final rawAvailable = earned + manualAdjustment - reserved;
    return AdminGuideSummary(
      user: user,
      completedConsultations: countByGuide[user.uid] ?? 0,
      totalEarnedPaise: earned,
      availableBalancePaise: rawAvailable < 0 ? 0 : rawAvailable,
    );
  }).toList()
    ..sort((a, b) => b.totalEarnedPaise.compareTo(a.totalEarnedPaise));

  return AdminPayoutsDashboard(
    revenue: AdminRevenueSummary(
      grossPaise: gross,
      commissionPaise: commission,
      guidePayoutEarnedPaise: guideEarned,
    ),
    pendingRequests: pendingRequests,
    totalPaidOutPaise: totalPaidOutPaise,
    paidRequestCount: paidRequests.length,
    guides: guides,
  );
});

/// This guide's own `guide_earnings` ledger, for the admin's per-guide
/// "View Ledger" drill-down -- reuses the same guide-facing provider the
/// guide's own Earnings screen watches, since admin is allowed to read any
/// guide's entries (see firestore.rules `match /guide_earnings/{guideId}`).
final adminGuideLedgerProvider = guideEarningsEntriesProvider;

/// Editable platform commission percentage, stored at `_meta/platform_config`
/// -- already covered by the existing `_meta/{docId}` rule (public read,
/// admin-only write), so this needs no firestore.rules change. This only
/// affects client-side display/estimates going forward: it does NOT
/// retroactively change past transactions, and it does NOT alter the split
/// actually enforced server-side by functions/src/consultationLogic.js
/// (`PLATFORM_FEE_PERCENT`) unless that Cloud Function is separately
/// updated to read this same config value.
final platformFeeConfigProvider = FutureProvider.autoDispose<double>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection(FirestoreConstants.metaCollection)
      .doc('platform_config')
      .get();
  final value = doc.data()?['platformFeePercent'];
  return value is num ? value.toDouble() : 20.0;
});

Future<void> savePlatformFeePercent(double percent) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.metaCollection)
      .doc('platform_config')
      .set({'platformFeePercent': percent}, SetOptions(merge: true));
}

/// Merges a manual balance adjustment + admin note into a guide's own
/// wallet metadata bag (see EarningsScreen's `_Wallet` for the guide-side
/// reader). Uses `set(..., merge: true)` on the whole `metadata.wallet`
/// map read fresh from Firestore first, not a blind overwrite, so it never
/// clobbers the guide's own linked UPI/bank details written concurrently.
Future<void> applyManualBalanceAdjustment({
  required String guideId,
  required int deltaPaise,
  required String note,
  required String adminUid,
}) async {
  final firestore = FirebaseFirestore.instance;
  final ref = firestore.collection(FirestoreConstants.usersCollection).doc(guideId);
  final snap = await ref.get();
  final metadata = Map<String, dynamic>.from(snap.data()?['metadata'] as Map? ?? {});
  final wallet = Map<String, dynamic>.from(metadata['wallet'] as Map? ?? {});
  final current = (wallet['manualAdjustmentPaise'] as num?)?.toInt() ?? 0;
  wallet['manualAdjustmentPaise'] = current + deltaPaise;
  final log = List<dynamic>.from(wallet['adjustmentLog'] as List? ?? []);
  log.add({
    'amountPaise': deltaPaise,
    'note': note,
    'adminUid': adminUid,
    'at': DateTime.now().toIso8601String(),
  });
  // Keep the log bounded -- an audit trail, not an unbounded array.
  wallet['adjustmentLog'] = log.length > 50 ? log.sublist(log.length - 50) : log;
  metadata['wallet'] = wallet;
  await ref.update({'metadata': metadata});
}
