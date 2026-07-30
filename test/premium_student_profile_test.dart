import 'package:college_reality_india/core/constants/display_name_constants.dart';
import 'package:college_reality_india/core/constants/profile_constants.dart';
import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/community/models/user_presence_model.dart';
import 'package:college_reality_india/features/profile/models/premium_student_profile.dart';
import 'package:college_reality_india/features/profile/models/student_trust_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  UserPresenceModel? presence,
  String verificationBadge = VerificationConstants.badgeVerifiedStudent,
  String displayNameMode = DisplayNameConstants.modeRealName,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: 'premium-uid',
    email: 'premium@test.com',
    displayName: 'Rahul Verma',
    verifiedRealName: 'Rahul Verma',
    publicDisplayName: 'Rahul Verma',
    displayNameMode: displayNameMode,
    photoURL: 'https://example.com/photo.jpg',
    collegeName: 'VIT Pune',
    course: 'B.Tech',
    branch: 'CSE',
    batchYear: 2023,
    aboutMe: 'Full-stack developer and campus ambassador.',
    interests: const ['Coding', 'Startups'],
    languagesKnown: const ['English', 'Hindi'],
    verificationBadge: verificationBadge,
    isEmailVerified: true,
    isPhoneVerified: true,
    presence: presence,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PremiumStudentProfile.fromUser', () {
    test('maps public fields without exposing private contact info', () {
      final profile = PremiumStudentProfile.fromUser(_user());

      expect(profile.uid, 'premium-uid');
      expect(profile.displayName, contains('Rahul'));
      expect(profile.collegeName, 'VIT Pune');
      expect(profile.course, 'B.Tech');
      expect(profile.branch, 'CSE');
      expect(profile.batchYear, 2023);
      expect(profile.interests, ['Coding', 'Startups']);
      expect(profile.verificationBadge, VerificationConstants.badgeVerifiedStudent);
      expect(profile.trust.trustScore, greaterThan(15));
    });

    test('uses Student fallback when display name empty', () {
      final now = DateTime(2026);
      final bare = UserModel(
        uid: 'bare',
        email: 'bare@test.com',
        displayName: '',
        publicDisplayName: '',
        createdAt: now,
        updatedAt: now,
      );
      expect(PremiumStudentProfile.fromUser(bare).displayName, startsWith('Student'));
    });

    test('copies presence and availability from user', () {
      final presence = const UserPresenceModel(
        isOnline: true,
        availabilityStatus: ProfileConstants.availabilityAvailable,
      );
      final profile = PremiumStudentProfile.fromUser(_user(presence: presence));
      expect(profile.presence.isOnline, isTrue);
      expect(profile.availabilityStatus, ProfileConstants.availabilityAvailable);
    });
  });

  group('PremiumStudentProfile.effectiveAvailability', () {
    test('returns offline when availability is offline regardless of online', () {
      final profile = PremiumStudentProfile(
        uid: '1',
        displayName: 'Test',
        trust: const StudentTrustModel(),
        presence: const UserPresenceModel(isOnline: true),
        availabilityStatus: ProfileConstants.availabilityOffline,
      );
      expect(profile.effectiveAvailability, ProfileConstants.availabilityOffline);
    });

    test('returns busy when availability is busy', () {
      final profile = PremiumStudentProfile(
        uid: '1',
        displayName: 'Test',
        trust: const StudentTrustModel(),
        presence: const UserPresenceModel(isOnline: true),
        availabilityStatus: ProfileConstants.availabilityBusy,
      );
      expect(profile.effectiveAvailability, ProfileConstants.availabilityBusy);
    });

    test('returns available when online and not busy/offline', () {
      final profile = PremiumStudentProfile(
        uid: '1',
        displayName: 'Test',
        trust: const StudentTrustModel(),
        presence: const UserPresenceModel(isOnline: true),
        availabilityStatus: ProfileConstants.availabilityAvailable,
      );
      expect(profile.effectiveAvailability, ProfileConstants.availabilityAvailable);
    });

    test('returns offline when not online and status is available', () {
      final profile = PremiumStudentProfile(
        uid: '1',
        displayName: 'Test',
        trust: const StudentTrustModel(),
        presence: const UserPresenceModel(isOnline: false),
        availabilityStatus: ProfileConstants.availabilityAvailable,
      );
      expect(profile.effectiveAvailability, ProfileConstants.availabilityOffline);
    });
  });
}
