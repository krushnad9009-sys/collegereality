import 'package:cloud_firestore/cloud_firestore.dart';

import '../../social/models/social_models.dart';
import '../../student_life/models/student_life_models.dart';
import '../services/college_community_feed_service.dart';

abstract class CollegeCommunityFeedRepository {
  Future<StudentCommunityModel> ensureCollegeCommunity({
    required String collegeId,
    required String collegeName,
  });
  Future<bool> isVerifiedPoster(String userId);
  Future<SocialPageResult<StudentCommunityPostModel>> fetchFeedPage({
    required String collegeId,
    required String mode,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit,
  });
  Future<StudentCommunityPostModel> createPost({
    required String collegeId,
    required String collegeName,
    required String authorId,
    required String authorDisplayName,
    required String postType,
    required String content,
    List<String> imageUrls,
    String pollQuestion,
    List<PollOptionModel> pollOptions,
    bool isAnonymous,
  });
  Future<void> toggleLikePost({required String postId, required String userId});
  Future<void> incrementShareCount(String postId);
  Future<void> addComment({
    required StudentCommunityPostModel post,
    required String authorId,
    required String authorDisplayName,
    required String content,
    String? parentCommentId,
  });
  Stream<List<StudentCommunityCommentModel>> watchPostComments(String postId);
  Future<void> votePoll({
    required String postId,
    required String userId,
    required String optionId,
  });
  Future<bool> hasVotedOnPoll(String postId, String userId);
  Future<void> reportPost({
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  });
  Future<void> reportComment({
    required String commentId,
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  });
  Future<void> pinPost(String postId, {required bool pinned});
  Future<void> hidePost(String postId);
}

class CollegeCommunityFeedRepositoryImpl implements CollegeCommunityFeedRepository {
  final CollegeCommunityFeedService _service;

  CollegeCommunityFeedRepositoryImpl(this._service);

  @override
  Future<StudentCommunityModel> ensureCollegeCommunity({
    required String collegeId,
    required String collegeName,
  }) =>
      _service.ensureCollegeCommunity(
        collegeId: collegeId,
        collegeName: collegeName,
      );

  @override
  Future<bool> isVerifiedPoster(String userId) =>
      _service.isVerifiedPoster(userId);

  @override
  Future<SocialPageResult<StudentCommunityPostModel>> fetchFeedPage({
    required String collegeId,
    required String mode,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) =>
      _service.fetchFeedPage(
        collegeId: collegeId,
        mode: mode,
        startAfter: startAfter,
        limit: limit,
      );

  @override
  Future<StudentCommunityPostModel> createPost({
    required String collegeId,
    required String collegeName,
    required String authorId,
    required String authorDisplayName,
    required String postType,
    required String content,
    List<String> imageUrls = const [],
    String pollQuestion = '',
    List<PollOptionModel> pollOptions = const [],
    bool isAnonymous = false,
  }) =>
      _service.createPost(
        collegeId: collegeId,
        collegeName: collegeName,
        authorId: authorId,
        authorDisplayName: authorDisplayName,
        postType: postType,
        content: content,
        imageUrls: imageUrls,
        pollQuestion: pollQuestion,
        pollOptions: pollOptions,
        isAnonymous: isAnonymous,
      );

  @override
  Future<void> toggleLikePost({required String postId, required String userId}) =>
      _service.toggleLikePost(postId: postId, userId: userId);

  @override
  Future<void> incrementShareCount(String postId) =>
      _service.incrementShareCount(postId);

  @override
  Future<void> addComment({
    required StudentCommunityPostModel post,
    required String authorId,
    required String authorDisplayName,
    required String content,
    String? parentCommentId,
  }) =>
      _service.addComment(
        post: post,
        authorId: authorId,
        authorDisplayName: authorDisplayName,
        content: content,
        parentCommentId: parentCommentId,
      );

  @override
  Stream<List<StudentCommunityCommentModel>> watchPostComments(String postId) =>
      _service.watchPostComments(postId);

  @override
  Future<void> votePoll({
    required String postId,
    required String userId,
    required String optionId,
  }) =>
      _service.votePoll(postId: postId, userId: userId, optionId: optionId);

  @override
  Future<bool> hasVotedOnPoll(String postId, String userId) =>
      _service.hasVotedOnPoll(postId, userId);

  @override
  Future<void> reportPost({
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) =>
      _service.reportPost(
        postId: postId,
        communityId: communityId,
        reporterId: reporterId,
        reason: reason,
      );

  @override
  Future<void> reportComment({
    required String commentId,
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) =>
      _service.reportComment(
        commentId: commentId,
        postId: postId,
        communityId: communityId,
        reporterId: reporterId,
        reason: reason,
      );

  @override
  Future<void> pinPost(String postId, {required bool pinned}) =>
      _service.pinPost(postId, pinned: pinned);

  @override
  Future<void> hidePost(String postId) => _service.hidePost(postId);
}
