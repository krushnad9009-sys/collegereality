import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/question_constants.dart';

class AnswerReplyModel {
  final String id;
  final String questionId;
  final String answerId;
  final String? parentReplyId;
  final String authorId;
  final String authorDisplayName;
  final bool isAnonymous;
  final String? reviewerBadge;
  final String body;
  final List<String> imageUrls;
  final List<String> mentionUserIds;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnswerReplyModel({
    required this.id,
    required this.questionId,
    required this.answerId,
    this.parentReplyId,
    required this.authorId,
    required this.authorDisplayName,
    this.isAnonymous = false,
    this.reviewerBadge,
    required this.body,
    this.imageUrls = const [],
    this.mentionUserIds = const [],
    this.status = QuestionConstants.statusPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublicVisible =>
      AnswerReplyModel.normalizeStatus(status) == QuestionConstants.statusPublished;

  static String normalizeStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return QuestionConstants.statusPublished;
    }
    return raw.trim().toLowerCase();
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory AnswerReplyModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AnswerReplyModel(
      id: docId ?? json['id'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      answerId: json['answerId'] as String? ?? '',
      parentReplyId: json['parentReplyId'] as String?,
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Student',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      reviewerBadge: json['reviewerBadge'] as String?,
      body: json['body'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mentionUserIds: (json['mentionUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: normalizeStatus(json['status'] as String?),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'answerId': answerId,
      'parentReplyId': parentReplyId,
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'isAnonymous': isAnonymous,
      'reviewerBadge': reviewerBadge,
      'body': body,
      'imageUrls': imageUrls,
      'mentionUserIds': mentionUserIds,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
