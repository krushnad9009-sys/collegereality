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
  final int stipendMin;
  final String duration;
  final int durationWeeks;
  final String workType;
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
    this.stipendMin = 0,
    this.duration = '',
    this.durationWeeks = 0,
    this.workType = CareersConstants.workTypeOffice,
    this.description = '',
    this.skills = const [],
    this.applyUrl = '',
    this.searchText = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => payType == CareersConstants.payTypePaid;
  bool get isRemote => workType == CareersConstants.workTypeRemote;

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
      stipendMin: (json['stipendMin'] as num?)?.toInt() ?? 0,
      duration: json['duration'] as String? ?? '',
      durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 0,
      workType: json['workType'] as String? ?? CareersConstants.workTypeOffice,
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
        'stipendMin': stipendMin,
        'duration': duration,
        'durationWeeks': durationWeeks,
        'workType': workType,
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
  final String eligibility;
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
    this.eligibility = '',
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
      eligibility: json['eligibility'] as String? ?? '',
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
        'eligibility': eligibility,
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
  final bool isVerified;
  final String? ownerUserId;
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
    this.isVerified = false,
    this.ownerUserId,
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
      isVerified: json['isVerified'] as bool? ?? false,
      ownerUserId: json['ownerUserId'] as String?,
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
        'isVerified': isVerified,
        if (ownerUserId != null) 'ownerUserId': ownerUserId,
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

class ApplicationModel {
  final String id;
  final String userId;
  final String? internshipId;
  final String? jobId;
  final String companyId;
  final String applicantName;
  final String coverNote;
  final String? resumeUrl;
  final String status;
  final DateTime createdAt;

  const ApplicationModel({
    required this.id,
    required this.userId,
    this.internshipId,
    this.jobId,
    required this.companyId,
    this.applicantName = '',
    this.coverNote = '',
    this.resumeUrl,
    this.status = CareersConstants.applicationStatusSubmitted,
    required this.createdAt,
  });

  bool get isInternship => internshipId != null && internshipId!.isNotEmpty;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ApplicationModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      internshipId: json['internshipId'] as String?,
      jobId: json['jobId'] as String?,
      companyId: json['companyId'] as String? ?? '',
      applicantName: json['applicantName'] as String? ?? '',
      coverNote: json['coverNote'] as String? ?? '',
      resumeUrl: json['resumeUrl'] as String?,
      status: json['status'] as String? ?? CareersConstants.applicationStatusSubmitted,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        if (internshipId != null) 'internshipId': internshipId,
        if (jobId != null) 'jobId': jobId,
        'companyId': companyId,
        'applicantName': applicantName,
        'coverNote': coverNote,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}

class StudentResumeModel {
  final String userId;
  final String fileName;
  final String downloadUrl;
  final int fileSizeBytes;
  final int score;
  final List<String> suggestions;
  final List<String> extractedSkills;
  final DateTime updatedAt;

  const StudentResumeModel({
    required this.userId,
    required this.fileName,
    required this.downloadUrl,
    this.fileSizeBytes = 0,
    this.score = 0,
    this.suggestions = const [],
    this.extractedSkills = const [],
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory StudentResumeModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return StudentResumeModel(
      userId: docId ?? json['userId'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'resume.pdf',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      suggestions: (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? const [],
      extractedSkills:
          (json['extractedSkills'] as List<dynamic>?)?.cast<String>() ?? const [],
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'fileSizeBytes': fileSizeBytes,
        'score': score,
        'suggestions': suggestions,
        'extractedSkills': extractedSkills,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CompanyAccountModel {
  final String userId;
  final String companyId;
  final String companyName;
  final bool isVerified;
  final DateTime createdAt;

  const CompanyAccountModel({
    required this.userId,
    required this.companyId,
    required this.companyName,
    this.isVerified = false,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory CompanyAccountModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CompanyAccountModel(
      userId: docId ?? json['userId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'companyId': companyId,
        'companyName': companyName,
        'isVerified': isVerified,
        'createdAt': createdAt.toIso8601String(),
      };
}

class CareersPageResult<T> {
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const CareersPageResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });
}
