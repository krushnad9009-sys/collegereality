import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../models/admin_models.dart';
import '../utils/admin_permissions.dart';
import 'admin_action_logger.dart';

class AdminUserModerationService {
  AdminUserModerationService({
    FirebaseFirestore? firestore,
    AdminActionLogger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? AdminActionLogger();

  final FirebaseFirestore _firestore;
  final AdminActionLogger _logger;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreConstants.usersCollection);

  Future<List<AdminUserSearchResult>> searchUsers(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final results = <AdminUserSearchResult>[];
    final seen = <String>{};

    Future<void> addFrom(Query<Map<String, dynamic>> q) async {
      final snap = await q.limit(AdminConstants.maxSearchUsers).get();
      for (final doc in snap.docs) {
        if (seen.contains(doc.id)) continue;
        seen.add(doc.id);
        results.add(_mapUser(doc));
      }
    }

    if (trimmed.contains('@')) {
      await addFrom(_users.where('email', isEqualTo: trimmed));
    }

    if (results.length < AdminConstants.maxSearchUsers) {
      final snap = await _users
          .orderBy('updatedAt', descending: true)
          .limit(AdminConstants.maxSearchUsers)
          .get();
      for (final doc in snap.docs) {
        if (seen.contains(doc.id)) continue;
        final data = doc.data();
        final email = data['email']?.toString().toLowerCase() ?? '';
        final name = data['displayName']?.toString().toLowerCase() ?? '';
        if (email.contains(trimmed) || name.contains(trimmed)) {
          seen.add(doc.id);
          results.add(_mapUser(doc));
        }
      }
    }

    return results.take(AdminConstants.maxSearchUsers).toList();
  }

  Future<List<AdminUserSearchResult>> listStaffUsers() async {
    final results = <AdminUserSearchResult>[];
    final seen = <String>{};
    for (final role in RoleConstants.staffUserTypes) {
      final snap = await _users
          .where('userType', isEqualTo: role)
          .limit(AdminConstants.maxSearchUsers)
          .get();
      for (final doc in snap.docs) {
        if (seen.contains(doc.id)) continue;
        seen.add(doc.id);
        results.add(_mapUser(doc));
      }
    }
    results.sort((a, b) => a.email.compareTo(b.email));
    return results;
  }

  AdminUserSearchResult _mapUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final presence = data['presence'] as Map<String, dynamic>?;
    final lastSeenRaw = presence?['lastSeenAt']?.toString();
    return AdminUserSearchResult(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      displayName: data['displayName']?.toString(),
      accountStatus:
          data['accountStatus']?.toString() ?? AdminConstants.accountStatusActive,
      verificationStatus: data['verificationStatus']?.toString() ?? '',
      verificationBadge: data['verificationBadge']?.toString() ?? '',
      userType: data['userType']?.toString() ?? RoleConstants.userTypeStudent,
      lastSeenAt: lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw) : null,
    );
  }

  Future<void> setUserRole({
    required String uid,
    required String newRole,
    required String actorUserType,
  }) async {
    final allowed = AdminPermissions.assignableRoles(actorUserType);
    if (!allowed.contains(newRole)) {
      throw StateError('You are not allowed to assign role: $newRole');
    }
    await _users.doc(uid).update({
      'userType': newRole,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'user.set_role',
      targetId: uid,
      targetType: 'user',
      metadata: {'userType': newRole},
    );
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? moderationNote,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (displayName != null) payload['displayName'] = displayName.trim();
    if (moderationNote != null) payload['moderationNote'] = moderationNote;
    await _users.doc(uid).update(payload);
    await _logger.log(
      action: 'user.edit',
      targetId: uid,
      targetType: 'user',
      metadata: payload,
    );
  }

  Future<void> suspendUser(
    String uid, {
    Duration duration = const Duration(days: 7),
    String? note,
  }) async {
    await _users.doc(uid).update({
      'accountStatus': AdminConstants.accountStatusSuspended,
      'suspendedUntil': DateTime.now().add(duration).toIso8601String(),
      'moderationNote': note ?? 'Suspended by admin',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'user.suspend',
      targetId: uid,
      targetType: 'user',
      metadata: {'days': duration.inDays},
    );
  }

  Future<void> banUser(String uid, {String? reason}) async {
    await _users.doc(uid).update({
      'accountStatus': AdminConstants.accountStatusBanned,
      'suspendedUntil': null,
      'moderationNote': reason ?? 'Banned by admin',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'user.ban',
      targetId: uid,
      targetType: 'user',
    );
  }

  Future<void> restoreAccount(String uid) async {
    await _users.doc(uid).update({
      'accountStatus': AdminConstants.accountStatusActive,
      'suspendedUntil': null,
      'moderationNote': null,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'user.restore',
      targetId: uid,
      targetType: 'user',
    );
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
    await _logger.log(
      action: 'user.delete',
      targetId: uid,
      targetType: 'user',
    );
  }

  Future<void> verifyStudentManually(String uid, {bool alumni = false}) async {
    await _users.doc(uid).update({
      'verificationStatus': VerificationConstants.statusApproved,
      'verificationBadge': alumni
          ? VerificationConstants.badgeVerifiedAlumni
          : VerificationConstants.badgeVerifiedStudent,
      'isVerified': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'user.verify',
      targetId: uid,
      targetType: 'user',
      metadata: {'alumni': alumni},
    );
  }

  Future<void> warnUser(String uid, {required String message}) async {
    await _users.doc(uid).update({
      'warningCount': FieldValue.increment(1),
      'lastWarningAt': DateTime.now().toIso8601String(),
      'moderationNote': message,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'user.warn',
      targetId: uid,
      targetType: 'user',
    );
  }

  Future<void> attachCollegePhotos(String collegeId, List<String> photoUrls) async {
    if (photoUrls.isEmpty) return;
    await _firestore.collection(FirestoreConstants.collegesCollection).doc(collegeId).update({
      'photoUrls': FieldValue.arrayUnion(photoUrls),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: 'college.attach_photos',
      targetId: collegeId,
      targetType: 'college',
      metadata: {'count': photoUrls.length},
    );
  }

  Future<void> setCollegeApproval(
    String collegeId, {
    required bool approved,
    String? note,
  }) async {
    await _firestore.collection(FirestoreConstants.collegesCollection).doc(collegeId).update({
      'isActive': approved,
      'adminNotes': note ?? (approved ? 'Approved' : 'Pending review'),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: approved ? 'college.publish' : 'college.unpublish',
      targetId: collegeId,
      targetType: 'college',
    );
  }

  Future<void> setCollegeFeatured(String collegeId, {required bool featured}) async {
    await _firestore.collection(FirestoreConstants.collegesCollection).doc(collegeId).update({
      'isFeatured': featured,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logger.log(
      action: featured ? 'college.feature' : 'college.unfeature',
      targetId: collegeId,
      targetType: 'college',
    );
  }
}
