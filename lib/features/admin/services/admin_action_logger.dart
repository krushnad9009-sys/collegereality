import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../ecosystem/models/ecosystem_models.dart';
import '../../ecosystem/services/audit_log_service.dart';

/// Logs every privileged admin action with actor identity and timestamp.
///
/// Writes to [audit_logs] (staff-readable) and mirrors to [super_admin_audit]
/// for Super Admin panel timelines.
class AdminActionLogger {
  AdminActionLogger({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuditLogService? auditLogService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _auditLogs = auditLogService ?? AuditLogService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuditLogService _auditLogs;
  final _uuid = const Uuid();

  Future<void> log({
    required String action,
    String? targetId,
    String? targetType,
    Map<String, dynamic> metadata = const {},
    String? actorNameOverride,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final actorName = actorNameOverride ??
        user.displayName ??
        user.email ??
        user.uid;

    try {
      await _auditLogs.log(
        action: action,
        actorId: user.uid,
        actorName: actorName,
        targetId: targetId,
        targetType: targetType,
        metadata: {
          ...metadata,
          'actorEmail': user.email ?? '',
        },
      );
    } catch (_) {
      // Primary audit write should not block admin UX if offline.
    }

    try {
      final id = _uuid.v4();
      final entry = AuditLogModel(
        id: id,
        action: action,
        actorId: user.uid,
        actorName: actorName,
        targetId: targetId,
        targetType: targetType,
        metadata: {
          ...metadata,
          'actorEmail': user.email ?? '',
        },
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(FirestoreConstants.superAdminAuditCollection)
          .doc(id)
          .set(entry.toJson());
    } catch (_) {
      // Mirror is best-effort.
    }
  }
}

final adminActionLoggerProvider = Provider<AdminActionLogger>((ref) {
  return AdminActionLogger();
});
