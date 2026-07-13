import 'package:cloud_firestore/cloud_firestore.dart';

class CutoffRecordModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String course;
  final String branch;
  final String examId;
  final String examName;
  final int year;
  final String round;
  final String category;
  final String gender;
  final String university;
  final String state;
  final int? cutoffRank;
  final double? cutoffPercentile;
  final double? cutoffMarks;
  final String scoreType;
  final DateTime updatedAt;

  const CutoffRecordModel({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.course,
    this.branch = '',
    required this.examId,
    required this.examName,
    required this.year,
    required this.round,
    required this.category,
    this.gender = 'All',
    this.university = '',
    this.state = '',
    this.cutoffRank,
    this.cutoffPercentile,
    this.cutoffMarks,
    this.scoreType = 'rank',
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory CutoffRecordModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CutoffRecordModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      course: json['course'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      examName: json['examName'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year - 1,
      round: json['round'] as String? ?? 'Round 1',
      category: json['category'] as String? ?? 'General',
      gender: json['gender'] as String? ?? 'All',
      university: json['university'] as String? ?? '',
      state: json['state'] as String? ?? '',
      cutoffRank: (json['cutoffRank'] as num?)?.toInt(),
      cutoffPercentile: (json['cutoffPercentile'] as num?)?.toDouble(),
      cutoffMarks: (json['cutoffMarks'] as num?)?.toDouble(),
      scoreType: json['scoreType'] as String? ?? 'rank',
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'course': course,
      'branch': branch,
      'examId': examId,
      'examName': examName,
      'year': year,
      'round': round,
      'category': category,
      'gender': gender,
      'university': university,
      'state': state,
      'cutoffRank': cutoffRank,
      'cutoffPercentile': cutoffPercentile,
      'cutoffMarks': cutoffMarks,
      'scoreType': scoreType,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
