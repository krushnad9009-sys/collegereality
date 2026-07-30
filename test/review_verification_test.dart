import 'package:college_reality_india/core/constants/review_verification.dart';
import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  required String status,
  required String badge,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    uid: 'u1',
    email: 'a@b.com',
    verificationStatus: status,
    verificationBadge: badge,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('canSubmitCollegeReview', () {
    test('allows approved verified students and alumni', () {
      expect(
        canSubmitCollegeReview(
          _user(
            status: VerificationConstants.statusApproved,
            badge: VerificationConstants.badgeVerifiedStudent,
          ),
        ),
        isTrue,
      );
      expect(
        canSubmitCollegeReview(
          _user(
            status: VerificationConstants.statusApproved,
            badge: VerificationConstants.badgeVerifiedAlumni,
          ),
        ),
        isTrue,
      );
    });

    test('rejects pending or unverified users', () {
      expect(
        canSubmitCollegeReview(
          _user(
            status: VerificationConstants.statusPendingReview,
            badge: VerificationConstants.badgeVerifiedStudent,
          ),
        ),
        isFalse,
      );
      expect(
        canSubmitCollegeReview(
          _user(
            status: VerificationConstants.statusApproved,
            badge: VerificationConstants.badgeNone,
          ),
        ),
        isFalse,
      );
    });
  });

  group('reviewerBadgeLabel', () {
    test('maps badge to label', () {
      expect(
        reviewerBadgeLabel(
          _user(
            status: VerificationConstants.statusApproved,
            badge: VerificationConstants.badgeVerifiedAlumni,
          ),
        ),
        'Verified Alumni',
      );
      expect(
        reviewerBadgeLabel(
          _user(
            status: VerificationConstants.statusApproved,
            badge: VerificationConstants.badgeVerifiedStudent,
          ),
        ),
        'Verified Student',
      );
      expect(
        reviewerBadgeLabel(
          _user(
            status: VerificationConstants.statusApproved,
            badge: VerificationConstants.badgeNone,
          ),
        ),
        'Verified',
      );
    });
  });
}
