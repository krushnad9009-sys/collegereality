import '../../core/constants/rating_parameters.dart';
import '../../core/constants/verification_constants.dart';
import '../auth/models/user_model.dart';
import '../verification/models/verification_request_model.dart';

/// Pure rules for the guide onboarding wizard (college review + document
/// verification), kept out of the widget so every gate is unit-tested.
class GuideOnboardingRules {
  GuideOnboardingRules._();

  /// The four categories every guide must rate (1-5). Keys are the app's
  /// existing review dimensions so these ratings feed the same college
  /// aggregates as any other review.
  static const List<({String key, String label})> ratingCategories = [
    (key: RatingParameters.overall, label: 'Overall'),
    (key: RatingParameters.teaching, label: 'Study / Academics'),
    (key: RatingParameters.campus, label: 'Campus Environment'),
    (key: RatingParameters.placements, label: 'Placements'),
  ];

  /// "Detailed" review: well above the 20-char minimum of a normal review.
  static const int minReviewChars = 150;
  static const int maxReviewChars = 3000;

  static bool collegeSelected(String? collegeId, String? collegeName) =>
      (collegeId?.trim().isNotEmpty ?? false) &&
      (collegeName?.trim().isNotEmpty ?? false);

  /// Step 1 is complete: college chosen and all four categories rated 1-5.
  static bool step1Complete({
    required String? collegeId,
    required String? collegeName,
    required Map<String, double> ratings,
  }) =>
      collegeSelected(collegeId, collegeName) &&
      ratingCategories.every((c) {
        final v = ratings[c.key] ?? 0;
        return v >= 1 && v <= 5;
      });

  /// Step 2 is complete: enough real text (whitespace doesn't count).
  static bool step2Complete(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ').length >= minReviewChars;

  static DocumentStepState documentStepState(
    UserModel user,
    VerificationRequestModel? activeRequest,
  ) {
    final verified = VerificationConstants.isApprovedStudentOrAlumni(
      user.verificationBadge,
      user.verificationStatus,
    );
    if (verified) return DocumentStepState.alreadyVerified;
    if (activeRequest != null) return DocumentStepState.underReview;
    return DocumentStepState.needsUpload;
  }

  /// Step 3 is complete when documents are already approved / in review,
  /// or the required number of distinct documents has been picked.
  static bool step3Complete(DocumentStepState state, int pickedDocuments) =>
      state != DocumentStepState.needsUpload ||
      pickedDocuments == VerificationConstants.requiredGuideVerificationDocs;
}

enum DocumentStepState {
  /// Must upload documents now.
  needsUpload,
  /// Documents already submitted and waiting for review -- nothing to upload.
  underReview,
  /// Already a verified student/alumni -- the review publishes immediately.
  alreadyVerified,
}
