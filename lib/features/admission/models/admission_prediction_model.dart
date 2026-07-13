import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionResultModel {
  final String collegeId;
  final String collegeName;
  final String course;
  final String branch;
  final String chance;
  final String explanation;
  final int? cutoffRank;
  final double? cutoffPercentile;
  final double? cutoffMarks;

  const PredictionResultModel({
    required this.collegeId,
    required this.collegeName,
    required this.course,
    this.branch = '',
    required this.chance,
    required this.explanation,
    this.cutoffRank,
    this.cutoffPercentile,
    this.cutoffMarks,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    return PredictionResultModel(
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      course: json['course'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      chance: json['chance'] as String? ?? 'low',
      explanation: json['explanation'] as String? ?? '',
      cutoffRank: (json['cutoffRank'] as num?)?.toInt(),
      cutoffPercentile: (json['cutoffPercentile'] as num?)?.toDouble(),
      cutoffMarks: (json['cutoffMarks'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collegeId': collegeId,
      'collegeName': collegeName,
      'course': course,
      'branch': branch,
      'chance': chance,
      'explanation': explanation,
      'cutoffRank': cutoffRank,
      'cutoffPercentile': cutoffPercentile,
      'cutoffMarks': cutoffMarks,
    };
  }
}

class AdmissionPredictionModel {
  final String id;
  final String userId;
  final String examId;
  final String examName;
  final int? rank;
  final double? percentile;
  final double? marks;
  final String scoreType;
  final String category;
  final String gender;
  final String state;
  final String homeUniversity;
  final List<PredictionResultModel> results;
  final String? label;
  final DateTime createdAt;

  const AdmissionPredictionModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.examName,
    this.rank,
    this.percentile,
    this.marks,
    required this.scoreType,
    required this.category,
    this.gender = 'All',
    this.state = '',
    this.homeUniversity = '',
    this.results = const [],
    this.label,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory AdmissionPredictionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AdmissionPredictionModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      examName: json['examName'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt(),
      percentile: (json['percentile'] as num?)?.toDouble(),
      marks: (json['marks'] as num?)?.toDouble(),
      scoreType: json['scoreType'] as String? ?? 'rank',
      category: json['category'] as String? ?? 'General',
      gender: json['gender'] as String? ?? 'All',
      state: json['state'] as String? ?? '',
      homeUniversity: json['homeUniversity'] as String? ?? '',
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => PredictionResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      label: json['label'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'examId': examId,
      'examName': examName,
      'rank': rank,
      'percentile': percentile,
      'marks': marks,
      'scoreType': scoreType,
      'category': category,
      'gender': gender,
      'state': state,
      'homeUniversity': homeUniversity,
      'results': results.map((e) => e.toJson()).toList(),
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
