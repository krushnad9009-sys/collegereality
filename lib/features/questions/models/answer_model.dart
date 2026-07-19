import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/question_constants.dart';

class AnswerModel {
  final String id;
  final String questionId;
  final String collegeId;
  final String authorId;
  final String authorDisplayName;
  final bool isAnonymous;
  final bool isVerifiedStudent;
  final String? reviewerBadge;
  final String body;
  final int upvoteCount;
  final int downvoteCount;
  final int score;
  final bool isMostHelpful;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnswerModel({
    required this.id,
    required this.questionId,
    required this.collegeId,
    required this.authorId,
    required this.authorDisplayName,
    this.isAnonymous = false,
    this.isVerifiedStudent = false,
    this.reviewerBadge,
    required this.body,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.score = 0,
    this.isMostHelpful = false,
    this.status = QuestionConstants.statusPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublicVisible =>
      normalizeStatus(status) == QuestionConstants.statusPublished;

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

  factory AnswerModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AnswerModel(
      id: docId ?? json['id'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Student',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isVerifiedStudent: json['isVerifiedStudent'] as bool? ?? false,
      reviewerBadge: json['reviewerBadge'] as String?,
      body: json['body'] as String? ?? '',
      upvoteCount: (json['upvoteCount'] as num?)?.toInt() ?? 0,
      downvoteCount: (json['downvoteCount'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      isMostHelpful: json['isMostHelpful'] as bool? ?? false,
      status: normalizeStatus(json['status'] as String?),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'collegeId': collegeId,
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'isAnonymous': isAnonymous,
      'isVerifiedStudent': isVerifiedStudent,
      'reviewerBadge': reviewerBadge,
      'body': body,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'score': score,
      'isMostHelpful': isMostHelpful,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AnswerModel copyWith({
    String? id,
    String? questionId,
    String? collegeId,
    String? authorId,
    String? authorDisplayName,
    bool? isAnonymous,
    bool? isVerifiedStudent,
    String? reviewerBadge,
    String? body,
    int? upvoteCount,
    int? downvoteCount,
    int? score,
    bool? isMostHelpful,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      collegeId: collegeId ?? this.collegeId,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerifiedStudent: isVerifiedStudent ?? this.isVerifiedStudent,
      reviewerBadge: reviewerBadge ?? this.reviewerBadge,
      body: body ?? this.body,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
      score: score ?? this.score,
      isMostHelpful: isMostHelpful ?? this.isMostHelpful,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
