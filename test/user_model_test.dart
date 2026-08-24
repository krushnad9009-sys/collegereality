import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/core/constants/role_constants.dart';
import 'package:college_reality_india/features/admin/utils/admin_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('fromJson/toJson round trip', () {
    final user = UserModel(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Ada',
      publicDisplayName: 'Ada',
      isEmailVerified: true,
      createdAt: now,
      updatedAt: now,
    );
    final restored = UserModel.fromJson(user.toJson());
    expect(restored.uid, 'u1');
    expect(restored.email, 'a@b.com');
    expect(restored.displayName, 'Ada');
    expect(restored.isEmailVerified, isTrue);
  });

  test('copyWith overrides fields', () {
    final user = UserModel(
      uid: 'u1',
      email: 'a@b.com',
      createdAt: now,
      updatedAt: now,
    );
    final next = user.copyWith(displayName: 'Bob', isPhoneVerified: true);
    expect(next.displayName, 'Bob');
    expect(next.isPhoneVerified, isTrue);
    expect(next.email, 'a@b.com');
  });

  test('fromJson uses provided timestamps', () {
    final user = UserModel.fromJson({
      'uid': 'x',
      'email': 'e@e.com',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    expect(user.uid, 'x');
    expect(user.email, 'e@e.com');
  });

  // Regression: a one-off Admin SDK script once wrote a native Firestore
  // Timestamp into `updatedAt` (which every other write path stores as an
  // ISO-8601 string) via firestore.SERVER_TIMESTAMP. cloud_firestore's
  // Timestamp is neither `DateTime` nor `String`, so
  // `json['updatedAt'] is DateTime ? ... : DateTime.parse(json['updatedAt']
  // as String)` threw a cast error on every read of that user's profile --
  // including the super-admin authorization check, which silently turned
  // that failure into "not admin" (see isSuperAdminProvider). Fixed by
  // writing updatedAt back as a string (tools/set_super_admin.py no longer
  // uses SERVER_TIMESTAMP); these two tests pin the contract so it can't
  // regress unnoticed again.
  group('updatedAt/createdAt must be strings, not Firestore Timestamps', () {
    test('a real-shaped document (string dates, userType super_admin) parses and authorizes', () {
      final user = UserModel.fromJson({
        'uid': 'LM8ZkpaxUWeEWM66UJfP99HuqFl1',
        'email': 'student@example.com',
        'userType': RoleConstants.userTypeSuperAdmin,
        'createdAt': '2026-07-12T11:34:28.738',
        'updatedAt': '2026-08-24T18:24:35.806',
      });
      expect(user.userType, RoleConstants.userTypeSuperAdmin);
      expect(AdminPermissions.isSuperAdmin(user.userType), isTrue);
    });

    test('a Firestore Timestamp in updatedAt throws instead of silently defaulting', () {
      expect(
        () => UserModel.fromJson({
          'uid': 'x',
          'email': 'e@e.com',
          'userType': RoleConstants.userTypeSuperAdmin,
          'createdAt': now.toIso8601String(),
          'updatedAt': Timestamp.fromDate(now),
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}