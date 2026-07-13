import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/careers_constants.dart';

class InternshipModel {
  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String city;
  final String payType;
  final String stipend;
  final String duration;
  final String description;
  final List<String> skills;
  final String applyUrl;
  final String searchText;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InternshipModel({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    required this.city,
    required this.payType,
    this.stipend = '',
    this.duration = '',
    this.description = '',
    this.skills = const [],
    this.applyUrl = '',
    this.searchText = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => payType == CareersConstants.payTypePaid;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory InternshipModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return InternshipModel(
      id: docId ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      payType: json['payType'] as String? ?? CareersConstants.payTypePaid,
      stipend: json['stipend'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      description: json['description'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? const [],
      applyUrl: json['applyUrl'] as String? ?? '',
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'companyId': companyId,
        'companyName': companyName,
        'city': city,
        'payType': payType,
        'stipend': stipend,
        'duration': duration,
        'description': description,
        'skills': skills,
        'applyUrl': applyUrl,
        'searchText': searchText,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class JobModel {
  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String location;
  final String jobLevel;
  final String workType;
  final double salaryMinLpa;
  final double salaryMaxLpa;
  final String description;
  final List<String> skills;
  final String applyUrl;
  final String searchText;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    required this.location,
    required this.jobLevel,
    required this.workType,
    this.salaryMinLpa = 0,
    this.salaryMaxLpa = 0,
    this.description = '',
    this.skills = const [],
    this.applyUrl = '',
    this.searchText = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get salaryRange {
    if (salaryMinLpa <= 0 && salaryMaxLpa <= 0) return 'Not disclosed';
    if (salaryMaxLpa <= 0) return '${salaryMinLpa.toStringAsFixed(1)} LPA+';
    return '${salaryMinLpa.toStringAsFixed(1)}–${salaryMaxLpa.toStringAsFixed(1)} LPA';
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory JobModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return JobModel(
      id: docId ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      jobLevel: json['jobLevel'] as String? ?? CareersConstants.jobLevelFresher,
      workType: json['workType'] as String? ?? CareersConstants.workTypeOffice,
      salaryMinLpa: (json['salaryMinLpa'] as num?)?.toDouble() ?? 0,
      salaryMaxLpa: (json['salaryMaxLpa'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? const [],
      applyUrl: json['applyUrl'] as String? ?? '',
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'companyId': companyId,
        'companyName': companyName,
        'location': location,
        'jobLevel': jobLevel,
        'workType': workType,
        'salaryMinLpa': salaryMinLpa,
        'salaryMaxLpa': salaryMaxLpa,
        'description': description,
        'skills': skills,
        'applyUrl': applyUrl,
        'searchText': searchText,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CompanyModel {
  final String id;
  final String name;
  final String nameLower;
  final String description;
  final String industry;
  final String website;
  final String hiringStatus;
  final double rating;
  final int reviewCount;
  final List<String> placementHistory;
  final String searchText;
  final bool isActive;
  final DateTime updatedAt;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.nameLower,
    this.description = '',
    this.industry = '',
    this.website = '',
    this.hiringStatus = CareersConstants.hiringActive,
    this.rating = 0,
    this.reviewCount = 0,
    this.placementHistory = const [],
    this.searchText = '',
    this.isActive = true,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CompanyModel(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameLower: json['nameLower'] as String? ?? '',
      description: json['description'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      website: json['website'] as String? ?? '',
      hiringStatus: json['hiringStatus'] as String? ?? CareersConstants.hiringActive,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      placementHistory:
          (json['placementHistory'] as List<dynamic>?)?.cast<String>() ?? const [],
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameLower': nameLower,
        'description': description,
        'industry': industry,
        'website': website,
        'hiringStatus': hiringStatus,
        'rating': rating,
        'reviewCount': reviewCount,
        'placementHistory': placementHistory,
        'searchText': searchText,
        'isActive': isActive,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CompanyReviewModel {
  final String id;
  final String companyId;
  final String userId;
  final String authorDisplayName;
  final bool isVerifiedStudent;
  final double rating;
  final String textReview;
  final String status;
  final DateTime createdAt;

  const CompanyReviewModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.authorDisplayName,
    this.isVerifiedStudent = false,
    required this.rating,
    this.textReview = '',
    this.status = CareersConstants.reviewStatusPublished,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory CompanyReviewModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CompanyReviewModel(
      id: docId ?? json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Student',
      isVerifiedStudent: json['isVerifiedStudent'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      textReview: json['textReview'] as String? ?? '',
      status: json['status'] as String? ?? CareersConstants.reviewStatusPublished,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'userId': userId,
        'authorDisplayName': authorDisplayName,
        'isVerifiedStudent': isVerifiedStudent,
        'rating': rating,
        'textReview': textReview,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}

class AlumniProfileModel {
  final String id;
  final String? userId;
  final String displayName;
  final String collegeName;
  final int batchYear;
  final String company;
  final String jobTitle;
  final String location;
  final String? linkedInUrl;
  final String successStory;
  final bool isVerifiedAlumni;
  final String searchText;
  final bool isActive;
  final DateTime updatedAt;

  const AlumniProfileModel({
    required this.id,
    this.userId,
    required this.displayName,
    required this.collegeName,
    required this.batchYear,
    required this.company,
    required this.jobTitle,
    this.location = '',
    this.linkedInUrl,
    this.successStory = '',
    this.isVerifiedAlumni = true,
    this.searchText = '',
    this.isActive = true,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory AlumniProfileModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AlumniProfileModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      batchYear: (json['batchYear'] as num?)?.toInt() ?? 2020,
      company: json['company'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      location: json['location'] as String? ?? '',
      linkedInUrl: json['linkedInUrl'] as String?,
      successStory: json['successStory'] as String? ?? '',
      isVerifiedAlumni: json['isVerifiedAlumni'] as bool? ?? true,
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'displayName': displayName,
        'collegeName': collegeName,
        'batchYear': batchYear,
        'company': company,
        'jobTitle': jobTitle,
        'location': location,
        'linkedInUrl': linkedInUrl,
        'successStory': successStory,
        'isVerifiedAlumni': isVerifiedAlumni,
        'searchText': searchText,
        'isActive': isActive,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
