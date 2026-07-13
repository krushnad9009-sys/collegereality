import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/question_constants.dart';

class QuestionModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String authorId;
  final String authorDisplayName;
  final bool isAnonymous;
  final bool isAuthorVerified;
  final String title;
  final String body;
  final String searchText;
  final int answerCount;
  final int mostHelpfulScore;
  final String? mostHelpfulAnswerId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuestionModel({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.authorId,
    required this.authorDisplayName,
    this.isAnonymous = false,
    this.isAuthorVerified = false,
    required this.title,
    this.body = '',
    this.searchText = '',
    this.answerCount = 0,
    this.mostHelpfulScore = 0,
    this.mostHelpfulAnswerId,
    this.status = QuestionConstants.statusPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublicVisible =>
      normalizeStatus(status) == QuestionConstants.statusPublished;

  bool get isUnanswered => answerCount <= 0;

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

  factory QuestionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return QuestionModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Student',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isAuthorVerified: json['isAuthorVerified'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      searchText: json['searchText'] as String? ?? '',
      answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
      mostHelpfulScore: (json['mostHelpfulScore'] as num?)?.toInt() ?? 0,
      mostHelpfulAnswerId: json['mostHelpfulAnswerId'] as String?,
      status: normalizeStatus(json['status'] as String?),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'isAnonymous': isAnonymous,
      'isAuthorVerified': isAuthorVerified,
      'title': title,
      'body': body,
      'searchText': searchText,
      'answerCount': answerCount,
      'mostHelpfulScore': mostHelpfulScore,
      'mostHelpfulAnswerId': mostHelpfulAnswerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  QuestionModel copyWith({
    String? id,
    String? collegeId,
    String? collegeName,
    String? authorId,
    String? authorDisplayName,
    bool? isAnonymous,
    bool? isAuthorVerified,
    String? title,
    String? body,
    String? searchText,
    int? answerCount,
    int? mostHelpfulScore,
    String? mostHelpfulAnswerId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isAuthorVerified: isAuthorVerified ?? this.isAuthorVerified,
      title: title ?? this.title,
      body: body ?? this.body,
      searchText: searchText ?? this.searchText,
      answerCount: answerCount ?? this.answerCount,
      mostHelpfulScore: mostHelpfulScore ?? this.mostHelpfulScore,
      mostHelpfulAnswerId: mostHelpfulAnswerId ?? this.mostHelpfulAnswerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
