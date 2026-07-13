import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../models/admin_models.dart';

class AdminUserModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  AdminUserSearchResult _mapUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final presence = data['presence'] as Map<String, dynamic>?;
    final lastSeenRaw = presence?['lastSeenAt']?.toString();
    return AdminUserSearchResult(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      displayName: data['displayName']?.toString(),
      accountStatus: data['accountStatus']?.toString() ?? AdminConstants.accountStatusActive,
      verificationStatus: data['verificationStatus']?.toString() ?? '',
      verificationBadge: data['verificationBadge']?.toString() ?? '',
      lastSeenAt: lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw) : null,
    );
  }

  Future<void> suspendUser(String uid, {Duration duration = const Duration(days: 7), String? note}) async {
    await _users.doc(uid).update({
      'accountStatus': AdminConstants.accountStatusSuspended,
      'suspendedUntil': DateTime.now().add(duration).toIso8601String(),
      'moderationNote': note ?? 'Suspended by admin',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> banUser(String uid, {String? reason}) async {
    await _users.doc(uid).update({
      'accountStatus': AdminConstants.accountStatusBanned,
      'suspendedUntil': null,
      'moderationNote': reason ?? 'Banned by admin',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> restoreAccount(String uid) async {
    await _users.doc(uid).update({
      'accountStatus': AdminConstants.accountStatusActive,
      'suspendedUntil': null,
      'moderationNote': null,
      'updatedAt': DateTime.now().toIso8601String(),
    });
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
  }

  Future<void> attachCollegePhotos(String collegeId, List<String> photoUrls) async {
    if (photoUrls.isEmpty) return;
    await _firestore.collection(FirestoreConstants.collegesCollection).doc(collegeId).update({
      'photoUrls': FieldValue.arrayUnion(photoUrls),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setCollegeApproval(String collegeId, {required bool approved, String? note}) async {
    await _firestore.collection(FirestoreConstants.collegesCollection).doc(collegeId).update({
      'isActive': approved,
      'adminNotes': note ?? (approved ? 'Approved' : 'Pending review'),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
