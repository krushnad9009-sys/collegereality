import '../../../core/constants/firestore_constants.dart';
import '../utils/admin_analytics_utils.dart';

String reportCollectionForSource(String source) {
  switch (source) {
    case 'Review':
      return FirestoreConstants.reviewReportsCollection;
    case 'Communication':
      return FirestoreConstants.userReportsCollection;
    case 'Community':
      return FirestoreConstants.communityReportsCollection;
    case 'Question':
      return FirestoreConstants.questionReportsCollection;
    case 'Answer':
      return FirestoreConstants.answerReportsCollection;
    case 'Campus Post':
      return FirestoreConstants.studentCommunityPostReportsCollection;
    case 'Campus Comment':
      return FirestoreConstants.studentCommunityCommentReportsCollection;
    default:
      return FirestoreConstants.reviewReportsCollection;
  }
}

String moderationLabel({required String reason, required String source}) {
  if (isLikelySpamReport(reason)) return 'Likely spam ($source)';
  if (isLikelyAbuseReport(reason)) return 'Likely abuse ($source)';
  return source;
}
