import '../../../core/constants/community_constants.dart';
import '../../../core/constants/social_constants.dart';

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String messageType;
  final String text;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? replyToMessageId;
  final List<String> readBy;
  final String status;
  final int likeCount;
  final List<String> likedBy;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    this.messageType = CommunityConstants.messageText,
    this.text = '',
    this.attachmentUrl,
    this.attachmentName,
    this.replyToMessageId,
    this.readBy = const [],
    this.status = SocialConstants.contentStatusVisible,
    this.likeCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  bool isReadBy(String userId) => readBy.contains(userId);

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ChatMessageModel(
      id: docId ?? json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Student',
      senderPhoto: json['senderPhoto'] as String?,
      messageType: json['messageType'] as String? ?? CommunityConstants.messageText,
      text: json['text'] as String? ?? '',
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
      replyToMessageId: json['replyToMessageId'] as String?,
      readBy: (json['readBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? SocialConstants.contentStatusVisible,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'messageType': messageType,
        'text': text,
        'attachmentUrl': attachmentUrl,
        'attachmentName': attachmentName,
        'replyToMessageId': replyToMessageId,
        'readBy': readBy,
        'status': status,
        'likeCount': likeCount,
        'likedBy': likedBy,
        'createdAt': createdAt.toIso8601String(),
      };
}
