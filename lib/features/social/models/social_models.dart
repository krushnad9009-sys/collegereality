import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/social_constants.dart';

class SocialPageResult<T> {
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const SocialPageResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });
}

class DiscussionFeedItem {
  final String id;
  final String feedType;
  final String title;
  final String preview;
  final String authorName;
  final String authorId;
  final bool isAnonymous;
  final int likeCount;
  final int replyCount;
  final String actionRoute;
  final DateTime createdAt;

  const DiscussionFeedItem({
    required this.id,
    required this.feedType,
    required this.title,
    this.preview = '',
    required this.authorName,
    this.authorId = '',
    this.isAnonymous = false,
    this.likeCount = 0,
    this.replyCount = 0,
    this.actionRoute = '',
    required this.createdAt,
  });

  String get feedTypeLabel {
    switch (feedType) {
      case SocialConstants.feedTypeCampusPost:
        return 'Campus Post';
      case SocialConstants.feedTypeCollegeChat:
        return 'College Chat';
      case SocialConstants.feedTypeQaThread:
        return 'Q&A Thread';
      case SocialConstants.feedTypeQuestion:
        return 'Question';
      default:
        return 'Discussion';
    }
  }
}
