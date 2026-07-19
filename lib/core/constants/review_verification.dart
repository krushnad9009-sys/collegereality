import '../../features/auth/models/user_model.dart';
import 'verification_constants.dart';

/// Whether the user may submit or edit a college review.
bool canSubmitCollegeReview(UserModel user) {
  if (user.verificationStatus != VerificationConstants.statusApproved) {
    return false;
  }
  return user.verificationBadge == VerificationConstants.badgeVerifiedStudent ||
      user.verificationBadge == VerificationConstants.badgeVerifiedAlumni;
}

String reviewerBadgeLabel(UserModel user) {
  switch (user.verificationBadge) {
    case VerificationConstants.badgeVerifiedAlumni:
      return 'Verified Alumni';
    case VerificationConstants.badgeVerifiedStudent:
      return 'Verified Student';
    default:
      return 'Verified';
  }
}
