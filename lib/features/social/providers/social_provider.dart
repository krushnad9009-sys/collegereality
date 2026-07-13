import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engagement/services/firestore_engagement_service.dart';
import '../models/social_models.dart';
import '../services/college_discussion_service.dart';
import '../services/moderation_service.dart';
import '../services/notification_bridge_service.dart';

abstract class SocialRepository {
  Future<SocialPageResult<DiscussionFeedItem>> fetchDiscussionFeedPage({
    required String collegeId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit,
  });
  Future<void> incrementMessageReportCount(String messageId);
  Future<void> incrementPostReportCount(String postId);
  Future<void> incrementQuestionReportCount(String questionId);
  Future<List<Map<String, dynamic>>> fetchAutoHiddenMessages({int limit});
  Future<List<Map<String, dynamic>>> fetchSpamFlaggedMessages({int limit});
  Future<void> restoreMessage(String messageId);
  Future<void> hideMessageAsSpam(String messageId);
  NotificationBridgeService get notificationBridge;
}

class SocialRepositoryImpl implements SocialRepository {
  final CollegeDiscussionService _discussionService;
  final ModerationService _moderationService;
  final NotificationBridgeService _notificationBridge;

  SocialRepositoryImpl({
    CollegeDiscussionService? discussionService,
    ModerationService? moderationService,
    NotificationBridgeService? notificationBridge,
  })  : _discussionService = discussionService ?? CollegeDiscussionService(),
        _moderationService = moderationService ?? ModerationService(),
        _notificationBridge = notificationBridge ??
            NotificationBridgeService(FirestoreEngagementService());

  @override
  Future<SocialPageResult<DiscussionFeedItem>> fetchDiscussionFeedPage({
    required String collegeId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) =>
      _discussionService.fetchDiscussionFeedPage(
        collegeId: collegeId,
        startAfter: startAfter,
        limit: limit,
      );

  @override
  Future<void> incrementMessageReportCount(String messageId) =>
      _moderationService.incrementMessageReportCount(messageId);

  @override
  Future<void> incrementPostReportCount(String postId) =>
      _moderationService.incrementPostReportCount(postId);

  @override
  Future<void> incrementQuestionReportCount(String questionId) =>
      _moderationService.incrementQuestionReportCount(questionId);

  @override
  Future<List<Map<String, dynamic>>> fetchAutoHiddenMessages({int limit = 50}) =>
      _moderationService.fetchAutoHiddenMessages(limit: limit);

  @override
  Future<List<Map<String, dynamic>>> fetchSpamFlaggedMessages({int limit = 50}) =>
      _moderationService.fetchSpamFlaggedMessages(limit: limit);

  @override
  Future<void> restoreMessage(String messageId) =>
      _moderationService.restoreMessage(messageId);

  @override
  Future<void> hideMessageAsSpam(String messageId) =>
      _moderationService.hideMessageAsSpam(messageId);

  @override
  NotificationBridgeService get notificationBridge => _notificationBridge;
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl();
});

final collegeDiscussionFeedProvider =
    FutureProvider.family<List<DiscussionFeedItem>, String>((ref, collegeId) async {
  final page = await ref
      .watch(socialRepositoryProvider)
      .fetchDiscussionFeedPage(collegeId: collegeId);
  return page.items;
});

final autoHiddenMessagesAdminProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(socialRepositoryProvider).fetchAutoHiddenMessages();
});

final spamFlaggedMessagesAdminProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(socialRepositoryProvider).fetchSpamFlaggedMessages();
});
