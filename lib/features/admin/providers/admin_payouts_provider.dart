import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../auth/models/user_model.dart';
import '../../consultations/models/payout_models.dart';
import '../../consultations/providers/consultation_provider.dart';

void _logFetchFailure(String label, Object e) {
  if (kDebugMode) debugPrint('[AdminPayouts] $label failed: $e');
}

/// Rolling windows for the dashboard's Daily/Weekly/Monthly/All-Time
/// filter toggle. `startDate` is inclusive; `null` means unbounded.
enum PayoutPeriod {
  daily,
  weekly,
  monthly,
  allTime;

  String get label => switch (this) {
        PayoutPeriod.daily => 'Daily',
        PayoutPeriod.weekly => 'Weekly',
        PayoutPeriod.monthly => 'Monthly',
        PayoutPeriod.allTime => 'All-Time',
      };

  DateTime? get startDate {
    final now = DateTime.now();
    return switch (this) {
      PayoutPeriod.daily => DateTime(now.year, now.month, now.day),
      PayoutPeriod.weekly => now.subtract(const Duration(days: 7)),
      PayoutPeriod.monthly => now.subtract(const Duration(days: 30)),
      PayoutPeriod.allTime => null,
    };
  }
}

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
  /// Revenue totals recomputed for each [PayoutPeriod] from the same
  /// bounded `payments` read -- toggling the filter is just a map lookup,
  /// no refetch.
  final Map<PayoutPeriod, AdminRevenueSummary> revenueByPeriod;
  final Map<PayoutPeriod, int> paidOutPaiseByPeriod;
  final Map<PayoutPeriod, int> paidRequestCountByPeriod;

  /// Always the CURRENT full pending queue, deliberately not period-filtered
  /// -- it's an actionable queue, not a historical report metric.
  final List<PayoutRequestModel> pendingRequests;

  /// Every request regardless of status, for the CSV export and the "All
  /// Withdrawal Requests" history list.
  final List<PayoutRequestModel> allRequests;

  final List<AdminGuideSummary> guides;

  const AdminPayoutsDashboard({
    required this.revenueByPeriod,
    required this.paidOutPaiseByPeriod,
    required this.paidRequestCountByPeriod,
    required this.pendingRequests,
    required this.allRequests,
    required this.guides,
  });

  AdminRevenueSummary revenueFor(PayoutPeriod period) =>
      revenueByPeriod[period] ?? const AdminRevenueSummary();
  int paidOutPaiseFor(PayoutPeriod period) => paidOutPaiseByPeriod[period] ?? 0;
  int paidRequestCountFor(PayoutPeriod period) => paidRequestCountByPeriod[period] ?? 0;

  /// All-zero/empty dashboard -- rendered when a collection is genuinely
  /// empty (a brand-new deployment with no payments/requests/guides yet)
  /// and also as the last-resort fallback if assembling the real dashboard
  /// throws for a reason none of the per-query safeguards already caught.
  /// Either way the screen shows real cards with ₹0 / 0 rather than an
  /// error page.
  static const empty = AdminPayoutsDashboard(
    revenueByPeriod: {},
    paidOutPaiseByPeriod: {},
    paidRequestCountByPeriod: {},
    pendingRequests: [],
    allRequests: [],
    guides: [],
  );
}

/// `.docs` of a query, or `[]` (never throws) on failure -- a transient
/// Firestore hiccup or a composite index still building degrades to "no
/// results" for that one input to the dashboard rather than failing the
/// whole thing.
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safeDocs(
  String label,
  Future<QuerySnapshot<Map<String, dynamic>>> future,
) async {
  try {
    return (await future).docs;
  } catch (e) {
    _logFetchFailure(label, e);
    return const [];
  }
}

DateTime? _parsePaymentDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

/// Everything the Super Admin Payouts panel needs, assembled from a small
/// number of bounded queries run concurrently and joined client-side --
/// the same convention AdminConsultationRevenueScreen already uses for the
/// `payments` collection, extended here across `payments`,
/// `payout_requests`, `users`, and the `guide_earnings` collection group.
///
/// Never throws: every sub-fetch degrades to an empty result on its own
/// (see PayoutService and `_safeDocs` above), every per-document parse is
/// wrapped so one malformed row can't take down the aggregate, and the
/// whole body is additionally wrapped so any other unexpected failure
/// still resolves to [AdminPayoutsDashboard.empty] instead of surfacing as
/// an AsyncValue.error the screen would render as "Unable to load".
final adminPayoutsDashboardProvider =
    FutureProvider.autoDispose<AdminPayoutsDashboard>((ref) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final payoutService = ref.watch(payoutServiceProvider);

    // Fire all four queries before awaiting any of them, so they run
    // concurrently rather than one after another.
    final paymentsFuture = _safeDocs(
      'payments',
      firestore
          .collection(FirestoreConstants.paymentsCollection)
          .where('status', whereIn: ['success', 'refunded'])
          .limit(1000)
          .get(),
    );
    final requestsFuture = payoutService.fetchAllPayoutRequests(limit: 2000);
    final entriesFuture = payoutService.fetchAllPayableEntries(limit: 5000);
    final guidesFuture = _safeDocs(
      'guides',
      firestore
          .collection(FirestoreConstants.usersCollection)
          .where('communicationSettings.isGuideAvailable', isEqualTo: true)
          .limit(300)
          .get(),
    );

    final paymentDocs = await paymentsFuture;
    final allRequests = await requestsFuture;
    final payableEntries = await entriesFuture;
    final guideDocs = await guidesFuture;

    // Revenue (gross/commission/guide-earned) per period, from the same
    // bounded `payments` read -- each payment doc is parsed once and then
    // bucketed into whichever periods it falls inside (a payment from
    // today counts toward Daily, Weekly, Monthly AND All-Time).
    final revenueByPeriod = <PayoutPeriod, AdminRevenueSummary>{};
    for (final period in PayoutPeriod.values) {
      final start = period.startDate;
      var gross = 0, commission = 0, guideEarned = 0;
      for (final doc in paymentDocs) {
        final data = doc.data();
        final at = _parsePaymentDate(data['createdAt']);
        if (start != null && (at == null || at.isBefore(start))) continue;
        gross += ((data['grossAmountPaise'] as num?) ?? 0).toInt();
        commission += ((data['platformFeePaise'] as num?) ?? 0).toInt();
        guideEarned += ((data['guideAmountPaise'] as num?) ?? 0).toInt();
      }
      revenueByPeriod[period] = AdminRevenueSummary(
        grossPaise: gross,
        commissionPaise: commission,
        guidePayoutEarnedPaise: guideEarned,
      );
    }

    final paidRequests = allRequests
        .where((r) => r.status == PayoutRequestConstants.statusPaid)
        .toList();
    final pendingRequests = allRequests
        .where((r) => r.status == PayoutRequestConstants.statusPending)
        .toList();

    // "Cleared" is keyed on decidedAt (when it was actually paid), not
    // requestedAt (when the guide asked for it) -- a request made last
    // month but paid today counts toward today's Daily total.
    final paidOutPaiseByPeriod = <PayoutPeriod, int>{};
    final paidRequestCountByPeriod = <PayoutPeriod, int>{};
    for (final period in PayoutPeriod.values) {
      final start = period.startDate;
      final inPeriod = paidRequests.where((r) {
        if (start == null) return true;
        final at = r.decidedAt;
        return at != null && !at.isBefore(start);
      });
      paidOutPaiseByPeriod[period] =
          inPeriod.fold<int>(0, (t, r) => t + r.amountPaise);
      paidRequestCountByPeriod[period] = inPeriod.length;
    }

    // Per-guide totals from the one bounded `payable` entries query, and
    // per-guide reserved (pending + already-paid request) amounts from the
    // combined requests query above -- avoids an N+1 read per guide.
    final earnedByGuide = <String, int>{};
    final countByGuide = <String, int>{};
    for (final e in payableEntries) {
      earnedByGuide[e.guideId] = (earnedByGuide[e.guideId] ?? 0) + e.amountPaise;
      countByGuide[e.guideId] = (countByGuide[e.guideId] ?? 0) + 1;
    }
    final reservedByGuide = <String, int>{};
    for (final r in allRequests) {
      if (r.status == PayoutRequestConstants.statusRejected) continue;
      reservedByGuide[r.guideId] = (reservedByGuide[r.guideId] ?? 0) + r.amountPaise;
    }

    final guides = <AdminGuideSummary>[];
    for (final doc in guideDocs) {
      // A guide account with a shape UserModel.fromJson can't parse (e.g. a
      // phone-only account missing the email field it requires non-null)
      // must be skipped, not allowed to crash the whole directory for
      // every other guide.
      final UserModel user;
      try {
        user = UserModel.fromJson(doc.data(), docId: doc.id);
      } catch (e) {
        _logFetchFailure('parse guide ${doc.id}', e);
        continue;
      }
      final earned = earnedByGuide[user.uid] ?? 0;
      final manualAdjustment = ((user.metadata?['wallet'] as Map?)
                  ?['manualAdjustmentPaise'] as num?)
              ?.toInt() ??
          0;
      final reserved = reservedByGuide[user.uid] ?? 0;
      final rawAvailable = earned + manualAdjustment - reserved;
      guides.add(AdminGuideSummary(
        user: user,
        completedConsultations: countByGuide[user.uid] ?? 0,
        totalEarnedPaise: earned,
        availableBalancePaise: rawAvailable < 0 ? 0 : rawAvailable,
      ));
    }
    guides.sort((a, b) => b.totalEarnedPaise.compareTo(a.totalEarnedPaise));

    return AdminPayoutsDashboard(
      revenueByPeriod: revenueByPeriod,
      paidOutPaiseByPeriod: paidOutPaiseByPeriod,
      paidRequestCountByPeriod: paidRequestCountByPeriod,
      pendingRequests: pendingRequests,
      allRequests: allRequests,
      guides: guides,
    );
  } catch (e) {
    _logFetchFailure('adminPayoutsDashboardProvider', e);
    return AdminPayoutsDashboard.empty;
  }
});

/// This guide's own `guide_earnings` ledger, for the admin's per-guide
/// "View Ledger" drill-down -- reuses the same guide-facing provider the
/// guide's own Earnings screen watches, since admin is allowed to read any
/// guide's entries (see firestore.rules `match /guide_earnings/{guideId}`).
final adminGuideLedgerProvider = guideEarningsEntriesProvider;

/// Builds a CSV of payout transaction records for the "Export CSV Report"
/// button -- Guide Name, Amount, UPI/Bank ID, Status, Requested Date,
/// Cleared Date, plus the transaction id / rejection reason where relevant.
String exportPayoutRequestsCsv(List<PayoutRequestModel> requests) {
  final buffer = StringBuffer();
  buffer.writeln(
    'Guide Name,Guide ID,Amount (INR),UPI/Bank ID,Status,Requested Date,Cleared Date,Transaction ID,Rejection Reason',
  );
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  for (final r in requests) {
    final amount = (r.amountPaise / 100).toStringAsFixed(2);
    final method = (r.payoutMethod.upiId?.isNotEmpty ?? false)
        ? r.payoutMethod.upiId!
        : (r.payoutMethod.bankAccountNumber ?? '');
    final status = r.status.isEmpty
        ? ''
        : '${r.status[0].toUpperCase()}${r.status.substring(1)}';
    final requested = dateFormat.format(r.requestedAt);
    final cleared = r.decidedAt != null ? dateFormat.format(r.decidedAt!) : '';
    buffer.writeln([
      _csvField(r.guideName),
      _csvField(r.guideId),
      amount,
      _csvField(method),
      status,
      requested,
      cleared,
      _csvField(r.transactionId ?? ''),
      _csvField(r.rejectionReason ?? ''),
    ].join(','));
  }
  return buffer.toString();
}

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Editable platform commission percentage, stored at `_meta/platform_config`
/// -- already covered by the existing `_meta/{docId}` rule (public read,
/// admin-only write), so this needs no firestore.rules change. This only
/// affects client-side display/estimates going forward: it does NOT
/// retroactively change past transactions, and it does NOT alter the split
/// actually enforced server-side by functions/src/consultationLogic.js
/// (`PLATFORM_FEE_PERCENT`) unless that Cloud Function is separately
/// updated to read this same config value. Falls back to 20% (never
/// throws) if the doc doesn't exist yet or the read fails -- a missing
/// config is a normal, expected state, not an error.
final platformFeeConfigProvider = FutureProvider.autoDispose<double>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.metaCollection)
        .doc('platform_config')
        .get();
    final value = doc.data()?['platformFeePercent'];
    return value is num ? value.toDouble() : 20.0;
  } catch (e) {
    _logFetchFailure('platformFeeConfigProvider', e);
    return 20.0;
  }
});

Future<void> savePlatformFeePercent(double percent) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.metaCollection)
      .doc('platform_config')
      .set({'platformFeePercent': percent}, SetOptions(merge: true));
}

/// "Auto-Approve Payouts Below (₹)" -- requests under this amount are
/// flagged in the pending queue for one-click instant approval instead of
/// the full transaction-id dialog (see _PendingRequestCard in
/// admin_payouts_screen.dart). This is a review-speed convenience only --
/// the admin still has to tap the button; nothing clears automatically in
/// the background without a Cloud Function, which doesn't exist for this
/// yet. Same `_meta/platform_config` doc as the commission percentage, so
/// no rules change is needed. Falls back to ₹500 (never throws).
final autoApproveThresholdPaiseProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.metaCollection)
        .doc('platform_config')
        .get();
    final value = doc.data()?['autoApproveThresholdPaise'];
    return value is num ? value.toInt() : 50000;
  } catch (e) {
    _logFetchFailure('autoApproveThresholdPaiseProvider', e);
    return 50000;
  }
});

Future<void> saveAutoApproveThresholdPaise(int paise) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.metaCollection)
      .doc('platform_config')
      .set({'autoApproveThresholdPaise': paise}, SetOptions(merge: true));
}

/// Merges a manual balance adjustment + admin note into a guide's own
/// wallet metadata bag (see EarningsScreen's `_Wallet` for the guide-side
/// reader). Uses `set(..., merge: true)` on the whole `metadata.wallet`
/// map read fresh from Firestore first, not a blind overwrite, so it never
/// clobbers the guide's own linked UPI/bank details written concurrently.
/// A user-initiated write -- deliberately NOT wrapped in a try/catch that
/// swallows the error; the caller reports failure to the admin.
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
