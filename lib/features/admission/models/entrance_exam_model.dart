import 'package:cloud_firestore/cloud_firestore.dart';

class ExamImportantDate {
  final String label;
  final DateTime date;

  const ExamImportantDate({required this.label, required this.date});

  factory ExamImportantDate.fromJson(Map<String, dynamic> json) {
    return ExamImportantDate(
      label: json['label'] as String? ?? '',
      date: _parseDate(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'date': date.toIso8601String(),
      };

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class EntranceExamModel {
  final String id;
  final String name;
  final String slug;
  final String category;
  final String conductingBody;
  final String eligibility;
  final String examPattern;
  final String syllabus;
  final List<ExamImportantDate> importantDates;
  final String officialWebsite;
  final String searchText;
  final String scoreType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EntranceExamModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    this.conductingBody = '',
    this.eligibility = '',
    this.examPattern = '',
    this.syllabus = '',
    this.importantDates = const [],
    this.officialWebsite = '',
    this.searchText = '',
    this.scoreType = 'rank',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory EntranceExamModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return EntranceExamModel(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? '',
      conductingBody: json['conductingBody'] as String? ?? '',
      eligibility: json['eligibility'] as String? ?? '',
      examPattern: json['examPattern'] as String? ?? '',
      syllabus: json['syllabus'] as String? ?? '',
      importantDates: (json['importantDates'] as List<dynamic>?)
              ?.map((e) => ExamImportantDate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      officialWebsite: json['officialWebsite'] as String? ?? '',
      searchText: json['searchText'] as String? ?? '',
      scoreType: json['scoreType'] as String? ?? 'rank',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'category': category,
      'conductingBody': conductingBody,
      'eligibility': eligibility,
      'examPattern': examPattern,
      'syllabus': syllabus,
      'importantDates': importantDates.map((e) => e.toJson()).toList(),
      'officialWebsite': officialWebsite,
      'searchText': searchText,
      'scoreType': scoreType,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
