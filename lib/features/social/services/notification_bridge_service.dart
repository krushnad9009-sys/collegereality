import '../../../config/router/route_names.dart';
import '../../../core/constants/engagement_constants.dart';
import '../../engagement/services/firestore_engagement_service.dart';

/// Bridges community and careers events into the in-app notification inbox.
class NotificationBridgeService {
  final FirestoreEngagementService _engagement;

  NotificationBridgeService(this._engagement);

  Future<void> notifyChatMessage({
    required String recipientId,
    required String senderName,
    required String conversationId,
    required String preview,
  }) async {
    await _engagement.notifyUser(
      userId: recipientId,
      type: EngagementConstants.typeNewChatMessage,
      category: EngagementConstants.categoryChat,
      title: 'New message from $senderName',
      body: preview,
      entityType: 'conversation',
      entityId: conversationId,
      actionRoute: RouteNames.communityChatPath(conversationId),
    );
  }

  Future<void> notifyNewAnswer({
    required String questionAuthorId,
    required String questionTitle,
    required String collegeId,
    required String questionId,
  }) async {
    await _engagement.notifyUser(
      userId: questionAuthorId,
      type: EngagementConstants.typeNewAnswer,
      category: EngagementConstants.categoryQuestions,
      title: 'New answer on your question',
      body: questionTitle,
      entityType: 'question',
      entityId: questionId,
      actionRoute: RouteNames.collegeQuestionPath(collegeId, questionId),
    );
  }

  Future<void> notifyAnswerReply({
    required String recipientId,
    required String questionTitle,
    required String collegeId,
    required String questionId,
  }) async {
    await _engagement.notifyUser(
      userId: recipientId,
      type: EngagementConstants.typeAnswerReply,
      category: EngagementConstants.categoryQuestions,
      title: 'New reply on a question you follow',
      body: questionTitle,
      entityType: 'question',
      entityId: questionId,
      actionRoute: RouteNames.collegeQuestionPath(collegeId, questionId),
    );
  }

  Future<void> notifyQuestionMention({
    required String recipientId,
    required String questionTitle,
    required String collegeId,
    required String questionId,
  }) async {
    await _engagement.notifyUser(
      userId: recipientId,
      type: EngagementConstants.typeQuestionMention,
      category: EngagementConstants.categoryQuestions,
      title: 'You were mentioned in a Q&A post',
      body: questionTitle,
      entityType: 'question',
      entityId: questionId,
      actionRoute: RouteNames.collegeQuestionPath(collegeId, questionId),
    );
  }

  Future<void> notifyAcceptedAnswer({
    required String answerAuthorId,
    required String questionTitle,
    required String collegeId,
    required String questionId,
  }) async {
    await _engagement.notifyUser(
      userId: answerAuthorId,
      type: EngagementConstants.typeAcceptedAnswer,
      category: EngagementConstants.categoryQuestions,
      title: 'Your answer was accepted',
      body: questionTitle,
      entityType: 'question',
      entityId: questionId,
      actionRoute: RouteNames.collegeQuestionPath(collegeId, questionId),
    );
  }

  Future<void> notifyNewReview({
    required String userId,
    required String collegeName,
    required String collegeId,
    required String reviewId,
  }) async {
    await _engagement.notifyUser(
      userId: userId,
      type: EngagementConstants.typeNewReview,
      category: EngagementConstants.categoryReviews,
      title: 'New review on $collegeName',
      body: 'A student posted a new review',
      entityType: 'review',
      entityId: reviewId,
      actionRoute: RouteNames.collegeDetailsPath(collegeId, tab: 'reviews'),
    );
  }

  Future<void> notifyNewJob({
    required String userId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) async {
    await _engagement.notifyUser(
      userId: userId,
      type: EngagementConstants.typeNewJob,
      category: EngagementConstants.categoryCareers,
      title: 'New job: $jobTitle',
      body: companyName,
      entityType: 'job',
      entityId: jobId,
      actionRoute: RouteNames.careersJobs,
    );
  }

  Future<void> notifyNewInternship({
    required String userId,
    required String title,
    required String companyName,
    required String internshipId,
  }) async {
    await _engagement.notifyUser(
      userId: userId,
      type: EngagementConstants.typeNewInternship,
      category: EngagementConstants.categoryCareers,
      title: 'New internship: $title',
      body: companyName,
      entityType: 'internship',
      entityId: internshipId,
      actionRoute: RouteNames.careersInternships,
    );
  }

  Future<void> notifyApplicationUpdate({
    required String userId,
    required String listingTitle,
    required String status,
    required String applicationId,
    required bool isInternship,
  }) async {
    await _engagement.notifyUser(
      userId: userId,
      type: EngagementConstants.typeApplicationUpdate,
      category: EngagementConstants.categoryCareers,
      title: 'Application $status',
      body: listingTitle,
      entityType: isInternship ? 'internship_application' : 'job_application',
      entityId: applicationId,
      actionRoute: RouteNames.careersSaved,
    );
  }

  Future<void> notifyCommunityComment({
    required String recipientId,
    required String preview,
    required String collegeId,
    required String collegeName,
    required String postId,
    required bool isReply,
  }) async {
    await _engagement.notifyUser(
      userId: recipientId,
      type: isReply
          ? EngagementConstants.typeCommunityReply
          : EngagementConstants.typeCommunityComment,
      category: EngagementConstants.categoryCommunity,
      title: isReply ? 'New reply on your comment' : 'New comment on your post',
      body: preview,
      entityType: 'community_post',
      entityId: postId,
      actionRoute: RouteNames.collegeCommunityFeedPath(collegeId, name: collegeName),
    );
  }

  Future<void> notifyReviewApproved({
    required String authorId,
    required String collegeName,
    required String collegeId,
    required String reviewId,
  }) async {
    await _engagement.notifyUser(
      userId: authorId,
      type: EngagementConstants.typeReviewApproved,
      category: EngagementConstants.categoryReviews,
      title: 'Your review was approved',
      body: collegeName,
      entityType: 'review',
      entityId: reviewId,
      actionRoute: RouteNames.collegeDetailsPath(collegeId, tab: 'reviews'),
    );
  }

  Future<void> notifyReviewInteraction({
    required String authorId,
    required String collegeName,
    required String collegeId,
    required String reviewId,
    required String preview,
  }) async {
    await _engagement.notifyUser(
      userId: authorId,
      type: EngagementConstants.typeReviewComment,
      category: EngagementConstants.categoryReviews,
      title: 'Activity on your review',
      body: preview.isNotEmpty ? preview : collegeName,
      entityType: 'review',
      entityId: reviewId,
      actionRoute: RouteNames.collegeDetailsPath(collegeId, tab: 'reviews'),
    );
  }

  Future<void> notifyVerificationUpdate({
    required String userId,
    required bool approved,
    String? collegeName,
  }) async {
    await _engagement.notifyUser(
      userId: userId,
      type: EngagementConstants.typeVerificationUpdate,
      category: EngagementConstants.categoryColleges,
      title: approved ? 'Verification approved' : 'Verification rejected',
      body: collegeName ?? '',
      entityType: 'verification',
      entityId: userId,
      actionRoute: RouteNames.verification,
    );
  }

  Future<void> notifyFollowedCollegePost({
    required String recipientId,
    required String collegeName,
    required String collegeId,
    required String postId,
    required String preview,
  }) async {
    await _engagement.notifyUser(
      userId: recipientId,
      type: EngagementConstants.typeCommunityPost,
      category: EngagementConstants.categoryCommunity,
      title: 'New post in $collegeName',
      body: preview,
      entityType: 'community_post',
      entityId: postId,
      actionRoute: RouteNames.collegeCommunityFeedPath(collegeId, name: collegeName),
    );
  }

  Future<void> notifyAdminAnnouncement({
    required String userId,
    required String title,
    required String body,
    String announcementId = '',
  }) async {
    await _engagement.notifyUser(
      userId: userId,
      type: EngagementConstants.typeAdminAnnouncement,
      category: EngagementConstants.categoryAdmin,
      title: title,
      body: body,
      entityType: 'announcement',
      entityId: announcementId.isNotEmpty ? announcementId : title,
      actionRoute: RouteNames.notifications,
    );
  }
}
