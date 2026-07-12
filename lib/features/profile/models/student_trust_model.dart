import '../../auth/models/user_model.dart';
import '../../../core/constants/verification_constants.dart';

class StudentTrustModel {
  final int trustScore;
  final double overallRating;
  final int totalRatings;
  final int helpfulVotes;

  const StudentTrustModel({
    this.trustScore = 0,
    this.overallRating = 0,
    this.totalRatings = 0,
    this.helpfulVotes = 0,
  });

  factory StudentTrustModel.fromUser(UserModel user) {
    return computeFromUser(user);
  }

  static StudentTrustModel computeFromUser(UserModel user) {
    var score = 15;
    if (user.verificationBadge != VerificationConstants.badgeNone) {
      score += 30;
    }
    if (user.isEmailVerified) score += 10;
    if (user.isPhoneVerified) score += 10;

    final stats = user.guideStats;
    if (stats.totalRatings > 0) {
      score += ((stats.overallRating / 5) * 20).round();
      score += ((stats.helpfulPercent / 100) * 15).round();
      score += (stats.totalRatings * 2).clamp(0, 10);
    }

    if (user.aboutMe != null && user.aboutMe!.trim().length >= 20) {
      score += 5;
    }
    if (user.interests.isNotEmpty) score += 5;

    final helpfulVotes =
        (stats.totalRatings * (stats.helpfulPercent / 100)).round();

    return StudentTrustModel(
      trustScore: score.clamp(0, 100),
      overallRating: stats.overallRating,
      totalRatings: stats.totalRatings,
      helpfulVotes: helpfulVotes,
    );
  }
}
