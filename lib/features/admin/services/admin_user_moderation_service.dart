import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/services/firestore_user_service.dart';
import '../models/admin_models.dart';
import '../utils/admin_permissions.dart';
import 'admin_action_logger.dart';

class AdminUserModerationService {
  AdminUserModerationService({
    FirebaseFirestore? firestore,
    AdminActionLogger? logger,
    FirestoreUserService? userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? AdminActionLogger(),
        _userService = userService ?? FirestoreUserService();

  final FirebaseFirestore _firestore;
  final AdminActionLogger _logger;
  // Reused only for its syncPublicProfile mirror -- the PII-free
  // `public_profiles` copy that ReviewCardWidget/other users' clients read
  // (Firestore rules only let the owner or staff read the full `users`
  // doc), so a badge grant/revoke here is visible to everyone in real time.
  final FirestoreUserService _userService;

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

    // Phone numbers are searched as digits-only so "98765" matches a
    // stored "+91 98765-43210" regardless of how it was typed on either
    // side of the comparison.
    final trimmedDigits = trimmed.replaceAll(RegExp(r'\D'), '');

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
        final collegeName = data['collegeName']?.toString().toLowerCase() ?? '';
        final phoneDigits =
            data['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
        final matchesPhone =
            trimmedDigits.isNotEmpty && phoneDigits.contains(trimmedDigits);
        if (email.contains(trimmed) ||
            name.contains(trimmed) ||
            collegeName.contains(trimmed) ||
            matchesPhone) {
          seen.add(doc.id);
          results.add(_mapUser(doc));
        }
      }
    }

    return results.take(AdminConstants.maxSearchUsers).toList();
  }

  /// Paginated listing of ALL registered users, newest-updated first --
  /// used for the User Management page's default (no search filter) view
  /// so admins land on a populated list instead of an empty "type
  /// something" prompt.
  /// [verifiedFilter]: null = All, true = Verified only, false = Unverified
  /// only. When set, this is a plain single-field equality query with NO
  /// `orderBy` -- combining an equality filter on one field with an
  /// `orderBy` on a different field needs a composite Firestore index that
  /// isn't defined for this collection, and adding one is a separate
  /// deploy step. Firestore's default (stable, but unspecified) document
  /// order is an acceptable trade-off here; the unfiltered "All" case below
  /// keeps the newest-updated-first order since it doesn't need one.
  Future<AdminPageResult<AdminUserSearchResult>> listUsersPage({
    String? startAfterDocumentId,
    bool? verifiedFilter,
    int limit = AdminConstants.defaultPageSize,
  }) async {
    Query<Map<String, dynamic>> q = verifiedFilter == null
        ? _users.orderBy('updatedAt', descending: true).limit(limit + 1)
        : _users.where('isVerified', isEqualTo: verifiedFilter).limit(limit + 1);
    if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
      final cursor = await _users.doc(startAfterDocumentId).get();
      if (cursor.exists) {
        q = q.startAfterDocument(cursor);
      }
    }

    final snap = await q.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPageResult(
      items: pageDocs.map(_mapUser).toList(),
      lastDocumentId: pageDocs.isEmpty ? null : pageDocs.last.id,
      hasMore: hasMore,
    );
  }

  /// Distinct city values among registered users in [state], for the City
  /// dropdown in the region analytics panel -- dynamic (reflects where
  /// students have actually registered) rather than a static gazetteer.
  /// Sampled over up to 500 matching docs rather than every user in the
  /// state; a single equality filter needs no composite index. Excludes
  /// the 'Not Provided' sentinel the permissions-onboarding screen writes
  /// when a user denies/skips location.
  Future<List<String>> getCitiesForState(String state) async {
    final snap = await _users.where('state', isEqualTo: state).limit(500).get();
    final cities = <String>{};
    for (final doc in snap.docs) {
      final city = doc.data()['city']?.toString().trim();
      if (city != null && city.isNotEmpty && city != 'Not Provided') {
        cities.add(city);
      }
    }
    final list = cities.toList()..sort();
    return list;
  }

  /// Total vs. active registered-student counts for a State/City selection
  /// (both optional -- omit either/both for "All"). [total] is an exact
  /// `.count()` aggregate over plain equality filters (no composite index
  /// needed). [active] ("isOnline OR seen in the last 7 days") can't be
  /// expressed as one Firestore query alongside those same equality
  /// filters without OR support + a composite index, so it's computed
  /// client-side over a bounded sample -- see RegionStudentStats.sampleCapped,
  /// which the UI should surface honestly rather than presenting an
  /// [active] count that quietly stopped being exact past 500 users.
  Future<RegionStudentStats> getRegionStudentStats({
    String? state,
    String? city,
  }) async {
    Query<Map<String, dynamic>> q = _users;
    if (state != null && state.isNotEmpty) {
      q = q.where('state', isEqualTo: state);
    }
    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }

    final countSnap = await q.count().get();
    final total = countSnap.count ?? 0;

    const sampleLimit = 500;
    final sampleSnap = await q.limit(sampleLimit).get();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    var active = 0;
    for (final doc in sampleSnap.docs) {
      final data = doc.data();
      final presence = data['presence'] as Map<String, dynamic>?;
      final isOnline = presence?['isOnline'] as bool? ?? false;
      final lastSeenRaw = presence?['lastSeenAt']?.toString();
      final lastSeen = lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw) : null;
      if (isOnline || (lastSeen != null && lastSeen.isAfter(cutoff))) {
        active++;
      }
    }

    return RegionStudentStats(
      total: total,
      active: active,
      sampled: sampleSnap.docs.length,
      sampleCapped: sampleSnap.docs.length >= sampleLimit,
    );
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
      photoURL: data['photoURL']?.toString(),
      phone: data['phone']?.toString(),
      collegeName: data['collegeName']?.toString(),
      collegeId: data['collegeId']?.toString(),
      city: data['city']?.toString(),
      state: data['state']?.toString(),
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

  /// Manual Super Admin override of a user's verified-student badge --
  /// independent of (and does not touch) the AI document-verification
  /// pipeline's own request/decision records; this only flips the same
  /// `isVerified`/`verificationBadge`/`verificationStatus` fields that
  /// pipeline writes, so every existing "is this user verified?" check in
  /// the app (profile badge, review card, guide directory, etc.) picks up
  /// either path identically. Also stamps `verifiedByAdminAt` and mirrors
  /// the change into `public_profiles` so any viewer -- not just the user
  /// themselves or staff -- sees the update, since Firestore rules only
  /// let the owner or staff read the full `users` doc.
  Future<void> setStudentVerified(
    String uid, {
    required bool verified,
    bool alumni = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    final update = {
      'verificationStatus': verified
          ? VerificationConstants.statusApproved
          : VerificationConstants.statusRejected,
      'verificationBadge': verified
          ? (alumni
              ? VerificationConstants.badgeVerifiedAlumni
              : VerificationConstants.badgeVerifiedStudent)
          : VerificationConstants.badgeNone,
      'isVerified': verified,
      'verifiedByAdminAt': now,
      'updatedAt': now,
    };
    await _users.doc(uid).update(update);
    await _userService.syncPublicProfile(uid, update);
    await _logger.log(
      action: verified ? 'user.verify' : 'user.unverify',
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
