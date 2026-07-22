import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/engagement_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../engagement/services/firestore_engagement_service.dart';
import '../../questions/utils/question_display_utils.dart';
import '../../social/models/social_models.dart';
import '../../social/services/moderation_service.dart';
import '../../social/utils/content_filter_utils.dart';
import '../../social/utils/moderation_utils.dart';
import '../../student_life/models/student_life_models.dart';

class CollegeCommunityFeedService {
  CollegeCommunityFeedService({
    FirebaseFirestore? firestore,
    ModerationService? moderationService,
    FirestoreEngagementService? engagementService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _moderationService = moderationService ?? ModerationService(),
        _engagement = engagementService ?? FirestoreEngagementService();

  final FirebaseFirestore _firestore;
  final ModerationService _moderationService;
  final FirestoreEngagementService _engagement;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _communities =>
      _firestore.collection(FirestoreConstants.studentCommunitiesCollection);
  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(FirestoreConstants.studentCommunityPostsCollection);
  CollectionReference<Map<String, dynamic>> get _postReports =>
      _firestore.collection(FirestoreConstants.studentCommunityPostReportsCollection);
  CollectionReference<Map<String, dynamic>> get _commentReports =>
      _firestore.collection(FirestoreConstants.studentCommunityCommentReportsCollection);
  CollectionReference<Map<String, dynamic>> get _pollVotes =>
      _firestore.collection(FirestoreConstants.studentCommunityPollVotesCollection);

  String communityIdFor(String collegeId) =>
      StudentLifeConstants.collegeFeedCommunityId(collegeId);

  /// Ensures every college has a canonical community board for its feed.
  Future<StudentCommunityModel> ensureCollegeCommunity({
    required String collegeId,
    required String collegeName,
  }) async {
    final trimmedId = collegeId.trim();
    final communityId = communityIdFor(trimmedId);
    final ref = _communities.doc(communityId);
    final existing = await ref.get();
    if (existing.exists) {
      return StudentCommunityModel.fromJson(existing.data()!, docId: existing.id);
    }

    final now = DateTime.now();
    final community = StudentCommunityModel(
      id: communityId,
      name: '$collegeName Community',
      collegeId: trimmedId,
      collegeName: collegeName.trim(),
      communityType: StudentLifeConstants.communityCollege,
      branchOrYear: 'All',
      description: 'Official community feed for $collegeName students and alumni.',
      verifiedStudentsOnly: true,
      isActive: true,
      updatedAt: now,
    );
    await ref.set(community.toJson());
    return community;
  }

  Future<bool> isVerifiedPoster(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    if (data['verificationStatus'] != VerificationConstants.statusApproved) {
      return false;
    }
    final badge = data['verificationBadge'] as String? ?? '';
    return badge == VerificationConstants.badgeVerifiedStudent ||
        badge == VerificationConstants.badgeVerifiedAlumni;
  }

  Future<SocialPageResult<StudentCommunityPostModel>> fetchFeedPage({
    required String collegeId,
    String mode = StudentLifeConstants.feedLatest,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    final trimmedId = collegeId.trim();
    Query<Map<String, dynamic>> query = _posts.where(
      'collegeId',
      isEqualTo: trimmedId,
    );

    switch (mode) {
      case StudentLifeConstants.feedPinned:
        query = query
            .where('isPinned', isEqualTo: true)
            .where('status', isEqualTo: StudentLifeConstants.statusPublished)
            .orderBy('pinnedAt', descending: true);
        break;
      case StudentLifeConstants.feedTrending:
        query = query
            .where('status', isEqualTo: StudentLifeConstants.statusPublished)
            .orderBy('engagementScore', descending: true)
            .orderBy('createdAt', descending: true);
        break;
      default:
        query = query
            .where('status', isEqualTo: StudentLifeConstants.statusPublished)
            .orderBy('createdAt', descending: true);
    }

    query = query.limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snap = await query.get();
      return _pageFromSnapshot(snap, limit);
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      // Fallback when composite index is not yet deployed.
      final fallback = await _posts
          .where('collegeId', isEqualTo: trimmedId)
          .where('status', isEqualTo: StudentLifeConstants.statusPublished)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2)
          .get();
      var items = fallback.docs
          .map((d) => StudentCommunityPostModel.fromJson(d.data(), docId: d.id))
          .toList();
      if (mode == StudentLifeConstants.feedPinned) {
        items = items.where((p) => p.isPinned).toList();
      } else if (mode == StudentLifeConstants.feedTrending) {
        items.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
      }
      items = items.take(limit).toList();
      return SocialPageResult(
        items: items,
        lastDocument: fallback.docs.isEmpty ? null : fallback.docs.last,
        hasMore: fallback.docs.length >= limit,
      );
    }
  }

  SocialPageResult<StudentCommunityPostModel> _pageFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
    int limit,
  ) {
    final items = snap.docs
        .map((d) => StudentCommunityPostModel.fromJson(d.data(), docId: d.id))
        .toList();
    return SocialPageResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

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
  }) async {
    if (!await isVerifiedPoster(authorId)) {
      throw CollegeCommunityFeedException(
        'Only verified students and alumni can create posts.',
      );
    }

    final community = await ensureCollegeCommunity(
      collegeId: collegeId,
      collegeName: collegeName,
    );

    final sanitized = sanitizeUserContent(
      postType == StudentLifeConstants.postPoll ? pollQuestion : content,
    );
    if (sanitized.isNotEmpty) {
      final moderation = moderateContent(sanitized);
      if (!moderation.allowed) {
        throw CollegeCommunityFeedException(
          'Post blocked: content violates community guidelines.',
        );
      }
    }

    final displayName = isAnonymous
        ? resolveAuthorDisplayName(
            userId: authorId,
            displayName: authorDisplayName,
            isAnonymous: true,
          )
        : authorDisplayName;

    final id = _uuid.v4();
    final now = DateTime.now();
    final post = StudentCommunityPostModel(
      id: id,
      communityId: community.id,
      collegeId: collegeId.trim(),
      collegeName: collegeName.trim(),
      authorId: authorId,
      authorDisplayName: displayName,
      isVerifiedStudent: true,
      postType: postType,
      content: content.trim(),
      imageUrls: imageUrls,
      pollQuestion: pollQuestion.trim(),
      pollOptions: pollOptions,
      pollEndsAt: postType == StudentLifeConstants.postPoll
          ? now.add(const Duration(days: 7))
          : null,
      status: StudentLifeConstants.statusPublished,
      isAnonymous: isAnonymous,
      createdAt: now,
      updatedAt: now,
    );

    await _posts.doc(id).set(post.toJson());

    final preview = postType == StudentLifeConstants.postPoll
        ? pollQuestion.trim()
        : content.trim();
    unawaited(
      _engagement.notifyFollowersOfCommunityPost(
        collegeId: collegeId,
        collegeName: collegeName,
        postId: id,
        preview: preview.length > 120 ? '${preview.substring(0, 120)}…' : preview,
        authorId: authorId,
      ),
    );

    return post;
  }

  Future<void> toggleLikePost({
    required String postId,
    required String userId,
  }) async {
    final ref = _posts.doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = (data['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      final commentCount = (data['commentCount'] as num?)?.toInt() ?? 0;
      final shareCount = (data['shareCount'] as num?)?.toInt() ?? 0;
      final score = _engagementScore(likedBy.length, commentCount, shareCount);
      tx.update(ref, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
        'engagementScore': score,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> incrementShareCount(String postId) async {
    final ref = _posts.doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final shareCount = ((data['shareCount'] as num?)?.toInt() ?? 0) + 1;
      final likeCount = (data['likeCount'] as num?)?.toInt() ?? 0;
      final commentCount = (data['commentCount'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'shareCount': shareCount,
        'engagementScore': _engagementScore(likeCount, commentCount, shareCount),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> addComment({
    required StudentCommunityPostModel post,
    required String authorId,
    required String authorDisplayName,
    required String content,
    String? parentCommentId,
  }) async {
    if (!await isVerifiedPoster(authorId)) {
      throw CollegeCommunityFeedException(
        'Only verified students and alumni can comment.',
      );
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw CollegeCommunityFeedException('Comment cannot be empty.');
    }

    final id = _uuid.v4();
    final postRef = _posts.doc(post.id);
    final commentRef = postRef
        .collection(FirestoreConstants.studentCommunityCommentsSubcollection)
        .doc(id);

    String? notifyUserId;
    String notificationTitle;
    String notificationBody;
    final isReply =
        parentCommentId != null && parentCommentId.trim().isNotEmpty;

    if (isReply) {
      final parentDoc = await postRef
          .collection(FirestoreConstants.studentCommunityCommentsSubcollection)
          .doc(parentCommentId)
          .get();
      notifyUserId = parentDoc.data()?['authorId'] as String?;
      notificationTitle = 'New reply on your comment';
      notificationBody = trimmed.length > 80 ? '${trimmed.substring(0, 80)}…' : trimmed;
    } else {
      notifyUserId = post.authorId;
      notificationTitle = 'New comment on your post';
      notificationBody = trimmed.length > 80 ? '${trimmed.substring(0, 80)}…' : trimmed;
    }

    await _firestore.runTransaction((tx) async {
      tx.set(commentRef, {
        'id': id,
        'postId': post.id,
        'communityId': post.communityId,
        'authorId': authorId,
        'authorDisplayName': authorDisplayName,
        'isVerifiedStudent': true,
        'content': trimmed,
        'parentCommentId': ?parentCommentId,
        'replyCount': 0,
        'status': StudentLifeConstants.statusPublished,
        'createdAt': DateTime.now().toIso8601String(),
      });

      final postSnap = await tx.get(postRef);
      final commentCount =
          (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      final likeCount = (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;
      final shareCount = (postSnap.data()?['shareCount'] as num?)?.toInt() ?? 0;
      tx.update(postRef, {
        'commentCount': commentCount + 1,
        'engagementScore': _engagementScore(likeCount, commentCount + 1, shareCount),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (isReply) {
        final parentRef = postRef
            .collection(FirestoreConstants.studentCommunityCommentsSubcollection)
            .doc(parentCommentId);
        final parentSnap = await tx.get(parentRef);
        if (parentSnap.exists) {
          final replyCount =
              (parentSnap.data()?['replyCount'] as num?)?.toInt() ?? 0;
          tx.update(parentRef, {'replyCount': replyCount + 1});
        }
      }
    });

    if (notifyUserId != null &&
        notifyUserId.isNotEmpty &&
        notifyUserId != authorId) {
      await _engagement.notifyUser(
        userId: notifyUserId,
        type: isReply
            ? EngagementConstants.typeCommunityReply
            : EngagementConstants.typeCommunityComment,
        category: EngagementConstants.categoryCommunity,
        title: notificationTitle,
        body: notificationBody,
        entityType: 'community_post',
        entityId: post.id,
        actionRoute: RouteNames.collegeCommunityFeedPath(
          post.collegeId,
          name: post.collegeName,
        ),
      );
    }
  }

  Stream<List<StudentCommunityCommentModel>> watchPostComments(String postId) {
    return _posts
        .doc(postId)
        .collection(FirestoreConstants.studentCommunityCommentsSubcollection)
        .where('status', isEqualTo: StudentLifeConstants.statusPublished)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                StudentCommunityCommentModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Future<void> votePoll({
    required String postId,
    required String userId,
    required String optionId,
  }) async {
    final voteDocId = '${postId}_$userId';
    if ((await _pollVotes.doc(voteDocId).get()).exists) {
      throw CollegeCommunityFeedException('You have already voted on this poll.');
    }

    await _firestore.runTransaction((tx) async {
      final postRef = _posts.doc(postId);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        throw CollegeCommunityFeedException('Poll not found.');
      }
      final data = postSnap.data()!;
      final options = (data['pollOptions'] as List<dynamic>)
          .map((e) => PollOptionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final updated = options
          .map((o) => o.id == optionId
              ? PollOptionModel(
                  id: o.id, label: o.label, voteCount: o.voteCount + 1)
              : o)
          .toList();
      tx.update(postRef, {
        'pollOptions': updated.map((o) => o.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      tx.set(_pollVotes.doc(voteDocId), {
        'postId': postId,
        'userId': userId,
        'optionId': optionId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<bool> hasVotedOnPoll(String postId, String userId) async {
    return (await _pollVotes.doc('${postId}_$userId').get()).exists;
  }

  Future<void> reportPost({
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) async {
    final id = _uuid.v4();
    await _postReports.doc(id).set({
      'id': id,
      'postId': postId,
      'communityId': communityId,
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': StudentLifeConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _moderationService.incrementPostReportCount(postId);
  }

  Future<void> reportComment({
    required String commentId,
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) async {
    final id = _uuid.v4();
    await _commentReports.doc(id).set({
      'id': id,
      'commentId': commentId,
      'postId': postId,
      'communityId': communityId,
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': StudentLifeConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> pinPost(String postId, {required bool pinned}) async {
    await _posts.doc(postId).update({
      'isPinned': pinned,
      'pinnedAt': pinned ? DateTime.now().toIso8601String() : null,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> hidePost(String postId) async {
    await _posts.doc(postId).update({
      'status': StudentLifeConstants.statusHidden,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  int _engagementScore(int likes, int comments, int shares) =>
      likes * 2 + comments * 3 + shares;
}

class CollegeCommunityFeedException implements Exception {
  final String message;
  CollegeCommunityFeedException(this.message);
  @override
  String toString() => message;
}
