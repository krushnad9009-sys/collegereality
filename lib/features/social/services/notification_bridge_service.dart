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
}
