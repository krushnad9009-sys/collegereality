import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_constants.dart';
import '../utils/admin_route_resolver.dart';

class _RevenueSummary {
  final int grossPaise;
  final int platformFeePaise;
  final int guideAmountPaise;
  final int refundedPaise;
  final int successfulCount;

  const _RevenueSummary({
    this.grossPaise = 0,
    this.platformFeePaise = 0,
    this.guideAmountPaise = 0,
    this.refundedPaise = 0,
    this.successfulCount = 0,
  });
}

final _revenueSummaryProvider = FutureProvider<_RevenueSummary>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestoreConstants.paymentsCollection)
      .where('status', whereIn: ['success', 'refunded'])
      .limit(500)
      .get();

  var gross = 0, fee = 0, guide = 0, refunded = 0, count = 0;
  for (final doc in snap.docs) {
    final data = doc.data();
    final g = ((data['grossAmountPaise'] as num?) ?? 0).toInt();
    gross += g;
    fee += ((data['platformFeePaise'] as num?) ?? 0).toInt();
    guide += ((data['guideAmountPaise'] as num?) ?? 0).toInt();
    if (data['status'] == 'refunded') refunded += g;
    count++;
  }
  return _RevenueSummary(
    grossPaise: gross,
    platformFeePaise: fee,
    guideAmountPaise: guide,
    refundedPaise: refunded,
    successfulCount: count,
  );
});

/// Platform revenue snapshot for admins — last 500 successful/refunded
/// payments (client-side aggregate; fine at this scale, matches how other
/// admin screens in this codebase already query directly rather than
/// maintaining a separate materialized-aggregate pipeline).
class AdminConsultationRevenueScreen extends ConsumerWidget {
  const AdminConsultationRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_revenueSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Revenue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AdminRouteResolver.home(context)),
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statTile('Gross volume', s.grossPaise),
            _statTile('Platform fee earned', s.platformFeePaise),
            _statTile('Paid out to guides', s.guideAmountPaise),
            _statTile('Refunded', s.refundedPaise),
            const SizedBox(height: 8),
            Text('${s.successfulCount} payment(s) in this window'),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, int paise) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '₹${(paise / 100).toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
