import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/guide_onboarding/guide_onboarding_rules.dart';
import 'package:college_reality_india/features/verification/models/verification_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({String badge = 'none', String status = 'incomplete'}) =>
    UserModel(
      uid: 'u1',
      email: 'u1@example.com',
      verificationBadge: badge,
      verificationStatus: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

VerificationRequestModel _pendingRequest() => VerificationRequestModel.fromJson(
      {
        'userId': 'u1',
        'documentType': VerificationConstants.documentCollegeId,
        'storagePath': 'x',
        'contentHash': 'h',
        'status': VerificationConstants.statusPendingReview,
        'createdAt': DateTime(2026).toIso8601String(),
      },
      docId: 'r1',
    );

void main() {
  const allRated = {
    'overall': 4.0,
    'teaching': 3.0,
    'campus': 5.0,
    'placements': 2.0,
  };

  group('step 1: college + 4 mandatory ratings', () {
    test('complete only with a college and all four categories rated', () {
      expect(
        GuideOnboardingRules.step1Complete(
            collegeId: 'c1', collegeName: 'IIT', ratings: allRated),
        isTrue,
      );
    });

    test('blocked without a college', () {
      expect(
        GuideOnboardingRules.step1Complete(
            collegeId: null, collegeName: null, ratings: allRated),
        isFalse,
      );
      expect(
        GuideOnboardingRules.step1Complete(
            collegeId: ' ', collegeName: 'IIT', ratings: allRated),
        isFalse,
      );
    });

    test('blocked while any category is unrated', () {
      final missing = Map.of(allRated)..remove('placements');
      expect(
        GuideOnboardingRules.step1Complete(
            collegeId: 'c1', collegeName: 'IIT', ratings: missing),
        isFalse,
      );
      expect(
        GuideOnboardingRules.step1Complete(
            collegeId: 'c1',
            collegeName: 'IIT',
            ratings: {...allRated, 'campus': 0}),
        isFalse,
      );
    });

    test('rates the four requested categories', () {
      expect(
        GuideOnboardingRules.ratingCategories.map((c) => c.label),
        ['Overall', 'Study / Academics', 'Campus Environment', 'Placements'],
      );
    });
  });

  group('step 2: detailed review text', () {
    test('needs the minimum characters', () {
      expect(GuideOnboardingRules.step2Complete('Good college.'), isFalse);
      expect(
        GuideOnboardingRules.step2Complete(
            'a' * GuideOnboardingRules.minReviewChars),
        isTrue,
      );
    });

    test('padding with whitespace does not count', () {
      final padded = 'short review${' ' * 300}';
      expect(GuideOnboardingRules.step2Complete(padded), isFalse);
    });
  });

  group('step 3: documents', () {
    test('an unverified user with nothing submitted must upload', () {
      final state = GuideOnboardingRules.documentStepState(_user(), null);
      expect(state, DocumentStepState.needsUpload);
      expect(GuideOnboardingRules.step3Complete(state, 1), isFalse);
      expect(
        GuideOnboardingRules.step3Complete(
            state, VerificationConstants.requiredGuideVerificationDocs),
        isTrue,
      );
    });

    test('documents already under review: nothing more to upload', () {
      final state =
          GuideOnboardingRules.documentStepState(_user(), _pendingRequest());
      expect(state, DocumentStepState.underReview);
      expect(GuideOnboardingRules.step3Complete(state, 0), isTrue);
    });

    test('an already verified student skips the upload', () {
      final state = GuideOnboardingRules.documentStepState(
        _user(
          badge: VerificationConstants.badgeVerifiedStudent,
          status: VerificationConstants.statusApproved,
        ),
        null,
      );
      expect(state, DocumentStepState.alreadyVerified);
      expect(GuideOnboardingRules.step3Complete(state, 0), isTrue);
    });
  });

  test('UserModel reads guideOnboarding.reviewId but never writes it back', () {
    final user = UserModel.fromJson({
      'uid': 'u1',
      'email': 'u1@example.com',
      'guideOnboarding': {'reviewId': 'rev1'},
      'createdAt': DateTime(2026).toIso8601String(),
      'updatedAt': DateTime(2026).toIso8601String(),
    }, docId: 'u1');
    expect(user.guideOnboardingReviewId, 'rev1');
    expect(user.copyWith(displayName: 'x').guideOnboardingReviewId, 'rev1');
    expect(user.toJson().containsKey('guideOnboarding'), isFalse);
  });
}
