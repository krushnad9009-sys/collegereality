import 'package:college_reality_india/features/auth/models/user_model.dart';
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
}