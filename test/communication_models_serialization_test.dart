import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:college_reality_india/features/communication/models/interaction_rating_model.dart';
import 'package:college_reality_india/features/communication/models/public_student_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3, 1, 15, 0);

  group('GuideStatsModel JSON', () {
    test('round-trip preserves rating aggregates', () {
      final original = GuideStatsModel(
        overallRating: 4.6,
        totalChats: 20,
        totalCalls: 15,
        totalRatings: 12,
        helpfulPercent: 92.0,
        respectfulPercent: 98.0,
        recommendPercent: 88.0,
        avgResponseTimeMinutes: 5,
        lastActiveAt: now,
        badgeTier: 'gold',
      );
      final restored = GuideStatsModel.fromJson(original.toJson());
      expect(restored.overallRating, 4.6);
      expect(restored.helpfulPercent, 92.0);
      expect(restored.lastActiveAt, now);
    });

    test('fromJson null returns defaults', () {
      expect(GuideStatsModel.fromJson(null), const GuideStatsModel());
    });

    test('copyWith updates badge tier', () {
      const stats = GuideStatsModel(badgeTier: 'bronze');
      expect(stats.copyWith(badgeTier: 'gold').badgeTier, 'gold');
    });
  });

  group('GuideCommunicationSettings JSON', () {
    test('round-trip preserves privacy toggles', () {
      const original = GuideCommunicationSettings(
        isGuideAvailable: true,
        videoCallsEnabled: false,
        cameraDefaultOn: false,
        blurBackground: true,
        allowPublicProfile: true,
      );
      final restored = GuideCommunicationSettings.fromJson(original.toJson());
      expect(restored.isGuideAvailable, isTrue);
      expect(restored.videoCallsEnabled, isFalse);
      expect(restored.allowPublicProfile, isTrue);
    });
  });

  group('InteractionRatingModel JSON', () {
    test('round-trip preserves rating flags', () {
      final original = InteractionRatingModel(
        id: 'rating-1',
        sessionId: 'call-1',
        raterId: 'user-a',
        rateeId: 'user-b',
        stars: 5,
        helpful: true,
        respectful: true,
        wouldRecommend: true,
        interactionType: 'call',
        createdAt: now,
      );
      final restored = InteractionRatingModel.fromJson(original.toJson());
      expect(restored.stars, 5);
      expect(restored.wouldRecommend, isTrue);
    });
  });

  group('UserBlockModel JSON', () {
    test('round-trip preserves block pair', () {
      final original = UserBlockModel(
        id: 'block-1',
        blockerId: 'user-a',
        blockedId: 'user-b',
        createdAt: now,
      );
      final restored = UserBlockModel.fromJson(original.toJson());
      expect(restored.blockerId, 'user-a');
      expect(restored.blockedId, 'user-b');
    });
  });

  group('UserReportModel JSON', () {
    test('round-trip preserves report details', () {
      final original = UserReportModel(
        id: 'report-1',
        reporterId: 'user-a',
        reportedId: 'user-b',
        sessionId: 'call-1',
        reason: 'harassment',
        details: 'Inappropriate language',
        status: 'open',
        createdAt: now,
      );
      final restored = UserReportModel.fromJson(original.toJson());
      expect(restored.reason, 'harassment');
      expect(restored.sessionId, 'call-1');
    });
  });

  group('PublicStudentProfile.fromUser', () {
    UserModel _user({bool allowPublic = true, String badge = VerificationConstants.badgeVerifiedStudent}) {
      return UserModel(
        uid: 'pub-uid',
        email: 'pub@test.com',
        displayName: 'Ananya Shah',
        course: 'B.Tech',
        branch: 'IT',
        batchYear: 2024,
        verificationBadge: badge,
        interests: const ['Design', 'Music'],
        communicationSettings: GuideCommunicationSettings(allowPublicProfile: allowPublic),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('maps public fields without contact info', () {
      final profile = PublicStudentProfile.fromUser(_user());
      expect(profile.uid, 'pub-uid');
      expect(profile.displayName, 'Ananya Shah');
      expect(profile.course, 'B.Tech');
      expect(profile.interests, ['Design', 'Music']);
      expect(profile.hasVerificationBadge, isTrue);
    });

    test('uses Student fallback for empty display name', () {
      final user = UserModel(
        uid: 'bare',
        email: 'bare@test.com',
        displayName: '',
        communicationSettings: const GuideCommunicationSettings(allowPublicProfile: true),
        createdAt: now,
        updatedAt: now,
      );
      expect(PublicStudentProfile.fromUser(user).displayName, 'Student');
    });

    test('throws when public profile disabled', () {
      expect(
        () => PublicStudentProfile.fromUser(_user(allowPublic: false)),
        throwsA(isA<StateError>()),
      );
    });

    test('hasVerificationBadge false for none badge', () {
      final profile = PublicStudentProfile.fromUser(_user(badge: VerificationConstants.badgeNone));
      expect(profile.hasVerificationBadge, isFalse);
    });
  });
}
