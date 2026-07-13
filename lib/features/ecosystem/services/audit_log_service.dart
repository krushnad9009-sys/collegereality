import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/ecosystem_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../models/ecosystem_models.dart';

/// Append-only audit trail for important platform actions.
class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> log({
    required String action,
    required String actorId,
    String actorName = '',
    String? targetId,
    String? targetType,
    Map<String, dynamic> metadata = const {},
  }) async {
    final id = _uuid.v4();
    final entry = AuditLogModel(
      id: id,
      action: action,
      actorId: actorId,
      actorName: actorName,
      targetId: targetId,
      targetType: targetType,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirestoreConstants.auditLogsCollection)
        .doc(id)
        .set(entry.toJson());
  }

  Future<List<AuditLogModel>> fetchPage({
    String? action,
    int limit = EcosystemConstants.pageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.auditLogsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (action != null && action.isNotEmpty) {
      query = query.where('action', isEqualTo: action);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => AuditLogModel.fromJson(d.data(), docId: d.id))
        .toList();
  }
}
