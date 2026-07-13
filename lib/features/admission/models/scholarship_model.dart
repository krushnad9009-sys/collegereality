import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/admission_constants.dart';

class ScholarshipModel {
  final String id;
  final String name;
  final String nameLower;
  final String providerType;
  final String? state;
  final List<String> courses;
  final List<String> categories;
  final double? maxIncomeLpa;
  final String amount;
  final String eligibility;
  final List<String> requiredDocuments;
  final DateTime? lastDate;
  final String officialWebsite;
  final String searchText;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScholarshipModel({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.providerType,
    this.state,
    this.courses = const [],
    this.categories = const [],
    this.maxIncomeLpa,
    required this.amount,
    this.eligibility = '',
    this.requiredDocuments = const [],
    this.lastDate,
    this.officialWebsite = '',
    this.searchText = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get providerLabel {
    switch (providerType) {
      case AdmissionConstants.providerCentralGovt:
        return 'Central Government';
      case AdmissionConstants.providerStateGovt:
        return 'State Government';
      case AdmissionConstants.providerPrivate:
        return 'Private';
      default:
        return providerType;
    }
  }

  bool get isExpired {
    if (lastDate == null) return false;
    return lastDate!.isBefore(DateTime.now());
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory ScholarshipModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ScholarshipModel(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameLower: json['nameLower'] as String? ?? '',
      providerType: json['providerType'] as String? ?? AdmissionConstants.providerCentralGovt,
      state: json['state'] as String?,
      courses: (json['courses'] as List<dynamic>?)?.cast<String>() ?? const [],
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? const [],
      maxIncomeLpa: (json['maxIncomeLpa'] as num?)?.toDouble(),
      amount: json['amount'] as String? ?? '',
      eligibility: json['eligibility'] as String? ?? '',
      requiredDocuments:
          (json['requiredDocuments'] as List<dynamic>?)?.cast<String>() ?? const [],
      lastDate: json['lastDate'] == null ? null : _parseDate(json['lastDate']),
      officialWebsite: json['officialWebsite'] as String? ?? '',
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameLower': nameLower,
      'providerType': providerType,
      'state': state,
      'courses': courses,
      'categories': categories,
      'maxIncomeLpa': maxIncomeLpa,
      'amount': amount,
      'eligibility': eligibility,
      'requiredDocuments': requiredDocuments,
      'lastDate': lastDate?.toIso8601String(),
      'officialWebsite': officialWebsite,
      'searchText': searchText,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
