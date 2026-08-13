import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/consultation_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../utils/admin_route_resolver.dart';
import '../services/admin_action_logger.dart';

final _adminConsultationsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.consultationsCollection)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs);
});

/// Consultation/payment/refund visibility for admins — reuses the existing
/// admin/super-admin shell (this screen is wired into both the in-app
/// admin section and the standalone super-admin panel, same as every
/// other AdminXScreen here). Force-cancel uses the `isAdmin()` branch
/// firestore.rules already grants on `consultations` updates — no new
/// rule needed.
class AdminConsultationsScreen extends ConsumerWidget {
  const AdminConsultationsScreen({super.key});

  Future<void> _forceCancel(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await doc.reference.update({
      'status': ConsultationConstants.statusCancelled,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancelReason': 'admin_intervention',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await AdminActionLogger().log(action: 'consultation.force_cancel', targetId: doc.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(_adminConsultationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AdminRouteResolver.home(context)),
        ),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('No consultations yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final status = data['status'] as String? ?? '';
              final price = data['priceInfo'] as Map<String, dynamic>? ?? const {};
              final gross = ((price['grossPaise'] as num?) ?? 0) / 100;
              final fee = ((price['platformFeePaise'] as num?) ?? 0) / 100;
              final refund = data['refundStatus'] as String? ?? 'none';
              final cancellable = status != ConsultationConstants.statusCompleted &&
                  !ConsultationConstants.terminalStatuses.contains(status);

              return ListTile(
                title: Text('${data['type']} · ₹${gross.toStringAsFixed(0)} · $status'),
                subtitle: Text(
                  'student: ${data['studentId']}\nguide: ${data['guideId']}\n'
                  'platform fee: ₹${fee.toStringAsFixed(0)} · refund: $refund',
                ),
                isThreeLine: true,
                trailing: cancellable
                    ? TextButton(
                        onPressed: () => _forceCancel(context, ref, doc),
                        child: const Text('Force cancel'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
