import '../../../core/constants/community_constants.dart';

class ChatConversationModel {
  final String id;
  final String type;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? collegeId;
  final String? collegeName;
  final String? course;
  final String? title;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, String> readReceipts;
  final Map<String, String> typingUsers;
  final String? authorId;
  final bool isResolved;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversationModel({
    required this.id,
    required this.type,
    this.participantIds = const [],
    this.participantNames = const {},
    this.collegeId,
    this.collegeName,
    this.course,
    this.title,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.readReceipts = const {},
    this.typingUsers = const {},
    this.authorId,
    this.isResolved = false,
    this.replyCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String displayTitle(String currentUserId) {
    if (title != null && title!.isNotEmpty) return title!;
    if (type == CommunityConstants.typePrivate) {
      for (final entry in participantNames.entries) {
        if (entry.key != currentUserId) return entry.value;
      }
      return 'Private Chat';
    }
    if (collegeName != null && course != null) {
      return '${CommunityConstants.roomTitle(type)} · $collegeName · $course';
    }
    if (collegeName != null) {
      return '${CommunityConstants.roomTitle(type)} · $collegeName';
    }
    return CommunityConstants.roomTitle(type);
  }

  String? peerIdFor(String userId) {
    if (type != CommunityConstants.typePrivate) return null;
    for (final id in participantIds) {
      if (id != userId) return id;
    }
    return null;
  }

  factory ChatConversationModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ChatConversationModel(
      id: docId ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? CommunityConstants.typePrivate,
      participantIds: (json['participantIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      participantNames: (json['participantNames'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
      course: json['course'] as String?,
      title: json['title'] as String?,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
      readReceipts: (json['readReceipts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      typingUsers: (json['typingUsers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      authorId: json['authorId'] as String?,
      isResolved: json['isResolved'] as bool? ?? false,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'course': course,
        'title': title,
        'lastMessageText': lastMessageText,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'readReceipts': readReceipts,
        'typingUsers': typingUsers,
        'authorId': authorId,
        'isResolved': isResolved,
        'replyCount': replyCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
