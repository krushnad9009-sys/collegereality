import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/social_constants.dart';
import '../../../core/constants/student_life_constants.dart';
import '../models/social_models.dart';
import '../utils/content_filter_utils.dart';

class CollegeDiscussionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection(FirestoreConstants.communityConversationsCollection);
  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection(FirestoreConstants.communityMessagesCollection);
  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(FirestoreConstants.studentCommunityPostsCollection);
  CollectionReference<Map<String, dynamic>> get _communities =>
      _firestore.collection(FirestoreConstants.studentCommunitiesCollection);
  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection(FirestoreConstants.collegeQuestionsCollection);

  Future<String?> _collegeRoomId(String collegeId) async {
    final snap = await _conversations
        .where('type', isEqualTo: CommunityConstants.typeCollege)
        .where('collegeId', isEqualTo: collegeId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<List<String>> _communityIdsForCollege(String collegeId) async {
    final snap = await _communities
        .where('collegeId', isEqualTo: collegeId)
        .where('isActive', isEqualTo: true)
        .limit(10)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<SocialPageResult<DiscussionFeedItem>> fetchDiscussionFeedPage({
    required String collegeId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = SocialConstants.defaultPageSize,
  }) async {
    final items = <DiscussionFeedItem>[];

    final roomId = await _collegeRoomId(collegeId);
    if (roomId != null) {
      Query<Map<String, dynamic>> msgQuery = _messages
          .where('conversationId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true)
          .limit(limit ~/ 2);
      if (startAfter != null) {
        msgQuery = msgQuery.startAfterDocument(startAfter);
      }
      final msgSnap = await msgQuery.get();
      for (final doc in msgSnap.docs) {
        final data = doc.data();
        if (data['status'] == SocialConstants.contentStatusHidden) continue;
        items.add(DiscussionFeedItem(
          id: doc.id,
          feedType: SocialConstants.feedTypeCollegeChat,
          title: data['senderName']?.toString() ?? 'Student',
          preview: buildContentPreview(data['text']?.toString() ?? ''),
          authorName: data['senderName']?.toString() ?? 'Student',
          authorId: data['senderId']?.toString() ?? '',
          likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
          replyCount: 0,
          actionRoute: RouteNames.communityChatPath(roomId),
          createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.now(),
        ));
      }
    }

    final communityIds = await _communityIdsForCollege(collegeId);
    if (communityIds.isNotEmpty) {
      final communityId = communityIds.first;
      final postSnap = await _posts
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: StudentLifeConstants.statusPublished)
          .orderBy('createdAt', descending: true)
          .limit(limit ~/ 2)
          .get();
      for (final doc in postSnap.docs) {
        final data = doc.data();
        final content = data['content']?.toString() ??
            data['pollQuestion']?.toString() ??
            '';
        items.add(DiscussionFeedItem(
          id: doc.id,
          feedType: SocialConstants.feedTypeCampusPost,
          title: data['authorDisplayName']?.toString() ?? 'Student',
          preview: buildContentPreview(content),
          authorName: data['authorDisplayName']?.toString() ?? 'Student',
          authorId: data['authorId']?.toString() ?? '',
          isAnonymous: data['isAnonymous'] as bool? ?? false,
          likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
          replyCount: (data['commentCount'] as num?)?.toInt() ?? 0,
          actionRoute: RouteNames.studentLifeCommunityBoardPath(communityId),
          createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.now(),
        ));
      }
    }

    final qaSnap = await _conversations
        .where('type', isEqualTo: CommunityConstants.typeQa)
        .where('collegeId', isEqualTo: collegeId)
        .orderBy('updatedAt', descending: true)
        .limit(5)
        .get();
    for (final doc in qaSnap.docs) {
      final data = doc.data();
      items.add(DiscussionFeedItem(
        id: doc.id,
        feedType: SocialConstants.feedTypeQaThread,
        title: data['title']?.toString() ?? 'Q&A Thread',
        preview: buildContentPreview(data['lastMessageText']?.toString() ?? ''),
        authorName: data['participantNames'] != null
            ? (data['participantNames'] as Map).values.first.toString()
            : 'Student',
        replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
        actionRoute: RouteNames.communityChatPath(doc.id),
        createdAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      ));
    }

    final questionSnap = await _questions
        .where('collegeId', isEqualTo: collegeId)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    for (final doc in questionSnap.docs) {
      final data = doc.data();
      items.add(DiscussionFeedItem(
        id: doc.id,
        feedType: SocialConstants.feedTypeQuestion,
        title: data['title']?.toString() ?? 'Question',
        preview: buildContentPreview(data['body']?.toString() ?? ''),
        authorName: data['authorDisplayName']?.toString() ?? 'Student',
        authorId: data['authorId']?.toString() ?? '',
        isAnonymous: data['isAnonymous'] as bool? ?? false,
        replyCount: (data['answerCount'] as num?)?.toInt() ?? 0,
        actionRoute: RouteNames.collegeQuestionPath(collegeId, doc.id),
        createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      ));
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = items.take(limit).toList();
    return SocialPageResult(
      items: page,
      hasMore: items.length >= limit,
    );
  }
}
