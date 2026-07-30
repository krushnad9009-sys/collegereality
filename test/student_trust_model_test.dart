import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:college_reality_india/features/profile/models/student_trust_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String badge = VerificationConstants.badgeNone,
  bool email = false,
  bool phone = false,
  GuideStatsModel? stats,
  String? about,
  List<String> interests = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: 'u1',
    email: 'a@b.com',
    verificationBadge: badge,
    isEmailVerified: email,
    isPhoneVerified: phone,
    guideStats: stats ?? const GuideStatsModel(),
    aboutMe: about,
    interests: interests,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('base score for unverified user', () {
    final trust = StudentTrustModel.computeFromUser(_user());
    expect(trust.trustScore, 15);
  });

  test('adds verification email phone and profile bonuses', () {
    final trust = StudentTrustModel.computeFromUser(
      _user(
        badge: VerificationConstants.badgeVerifiedStudent,
        email: true,
        phone: true,
        about: 'I love helping juniors choose colleges.',
        interests: ['CSE', 'Placements'],
        stats: const GuideStatsModel(
          overallRating: 5,
          totalRatings: 4,
          helpfulPercent: 100,
        ),
      ),
    );
    expect(trust.trustScore, greaterThan(70));
    expect(trust.trustScore, lessThanOrEqualTo(100));
    expect(trust.totalRatings, 4);
    expect(trust.helpfulVotes, 4);
  });
}