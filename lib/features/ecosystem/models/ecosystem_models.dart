import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/ecosystem_constants.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class EditHistoryEntry {
  final String action;
  final String field;
  final String? oldValue;
  final String? newValue;
  final String actorId;
  final String actorName;
  final DateTime at;

  const EditHistoryEntry({
    required this.action,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.actorId,
    this.actorName = '',
    required this.at,
  });

  factory EditHistoryEntry.fromJson(Map<String, dynamic> json) {
    return EditHistoryEntry(
      action: json['action'] as String? ?? '',
      field: json['field'] as String? ?? '',
      oldValue: json['oldValue'] as String?,
      newValue: json['newValue'] as String?,
      actorId: json['actorId'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      at: _parseDate(json['at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
        'actorId': actorId,
        'actorName': actorName,
        'at': at.toIso8601String(),
      };
}

class CollegeRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String name;
  final String nameLower;
  final String city;
  final String cityLower;
  final String state;
  final String address;
  final String? website;
  final String? universityName;
  final String? photoUrl;
  final String notes;
  final String status;
  final String? adminNotes;
  final String? approvedCollegeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollegeRequestModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.name,
    this.nameLower = '',
    required this.city,
    this.cityLower = '',
    required this.state,
    this.address = '',
    this.website,
    this.universityName,
    this.photoUrl,
    this.notes = '',
    this.status = EcosystemConstants.statusPending,
    this.adminNotes,
    this.approvedCollegeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollegeRequestModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeRequestModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameLower: json['nameLower'] as String? ?? '',
      city: json['city'] as String? ?? '',
      cityLower: json['cityLower'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      website: json['website'] as String?,
      universityName: json['universityName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? EcosystemConstants.statusPending,
      adminNotes: json['adminNotes'] as String?,
      approvedCollegeId: json['approvedCollegeId'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'name': name,
        'nameLower': nameLower,
        'city': city,
        'cityLower': cityLower,
        'state': state,
        'address': address,
        'website': website,
        'universityName': universityName,
        'photoUrl': photoUrl,
        'notes': notes,
        'status': status,
        'adminNotes': adminNotes,
        'approvedCollegeId': approvedCollegeId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CollegeEditSuggestionModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String userId;
  final String userName;
  final String field;
  final String currentValue;
  final String suggestedValue;
  final String reason;
  final String status;
  final List<EditHistoryEntry> editHistory;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollegeEditSuggestionModel({
    required this.id,
    required this.collegeId,
    this.collegeName = '',
    required this.userId,
    this.userName = '',
    required this.field,
    this.currentValue = '',
    required this.suggestedValue,
    this.reason = '',
    this.status = EcosystemConstants.statusPending,
    this.editHistory = const [],
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollegeEditSuggestionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeEditSuggestionModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      field: json['field'] as String? ?? '',
      currentValue: json['currentValue'] as String? ?? '',
      suggestedValue: json['suggestedValue'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? EcosystemConstants.statusPending,
      editHistory: (json['editHistory'] as List<dynamic>?)
              ?.map((e) => EditHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviewedBy: json['reviewedBy'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'userId': userId,
        'userName': userName,
        'field': field,
        'currentValue': currentValue,
        'suggestedValue': suggestedValue,
        'reason': reason,
        'status': status,
        'editHistory': editHistory.map((e) => e.toJson()).toList(),
        'reviewedBy': reviewedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CollegeDataReportModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String userId;
  final String userName;
  final String reportType;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollegeDataReportModel({
    required this.id,
    required this.collegeId,
    this.collegeName = '',
    required this.userId,
    this.userName = '',
    required this.reportType,
    this.description = '',
    this.status = EcosystemConstants.statusPending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollegeDataReportModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeDataReportModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      reportType: json['reportType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? EcosystemConstants.statusPending,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'userId': userId,
        'userName': userName,
        'reportType': reportType,
        'description': description,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CollegeClaimModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String userId;
  final String userName;
  final String officialEmail;
  final String representativeName;
  final String representativeDesignation;
  final String? authorizationLetterUrl;
  final String? representativeIdUrl;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollegeClaimModel({
    required this.id,
    required this.collegeId,
    this.collegeName = '',
    required this.userId,
    this.userName = '',
    required this.officialEmail,
    required this.representativeName,
    this.representativeDesignation = '',
    this.authorizationLetterUrl,
    this.representativeIdUrl,
    this.status = EcosystemConstants.statusPending,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollegeClaimModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeClaimModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      officialEmail: json['officialEmail'] as String? ?? '',
      representativeName: json['representativeName'] as String? ?? '',
      representativeDesignation: json['representativeDesignation'] as String? ?? '',
      authorizationLetterUrl: json['authorizationLetterUrl'] as String?,
      representativeIdUrl: json['representativeIdUrl'] as String?,
      status: json['status'] as String? ?? EcosystemConstants.statusPending,
      adminNotes: json['adminNotes'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'userId': userId,
        'userName': userName,
        'officialEmail': officialEmail,
        'representativeName': representativeName,
        'representativeDesignation': representativeDesignation,
        'authorizationLetterUrl': authorizationLetterUrl,
        'representativeIdUrl': representativeIdUrl,
        'status': status,
        'adminNotes': adminNotes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CollegeAccountModel {
  final String userId;
  final String collegeId;
  final String collegeName;
  final String officialEmail;
  final bool isVerified;
  final bool showOfficialBadge;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollegeAccountModel({
    required this.userId,
    required this.collegeId,
    this.collegeName = '',
    this.officialEmail = '',
    this.isVerified = false,
    this.showOfficialBadge = false,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollegeAccountModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeAccountModel(
      userId: docId ?? json['userId'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      officialEmail: json['officialEmail'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      showOfficialBadge: json['showOfficialBadge'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null ? _parseDate(json['verifiedAt']) : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'officialEmail': officialEmail,
        'isVerified': isVerified,
        'showOfficialBadge': showOfficialBadge,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class FacultyVerificationRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String collegeId;
  final String collegeName;
  final String officialEmail;
  final String? facultyIdUrl;
  final String department;
  final String designation;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FacultyVerificationRequestModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.collegeId,
    this.collegeName = '',
    required this.officialEmail,
    this.facultyIdUrl,
    this.department = '',
    this.designation = '',
    this.status = EcosystemConstants.statusPending,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacultyVerificationRequestModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return FacultyVerificationRequestModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      officialEmail: json['officialEmail'] as String? ?? '',
      facultyIdUrl: json['facultyIdUrl'] as String?,
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      status: json['status'] as String? ?? EcosystemConstants.statusPending,
      adminNotes: json['adminNotes'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'officialEmail': officialEmail,
        'facultyIdUrl': facultyIdUrl,
        'department': department,
        'designation': designation,
        'status': status,
        'adminNotes': adminNotes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CollegeOfficialContentModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String authorId;
  final String section;
  final String title;
  final String body;
  final List<String> mediaUrls;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollegeOfficialContentModel({
    required this.id,
    required this.collegeId,
    this.collegeName = '',
    required this.authorId,
    required this.section,
    required this.title,
    this.body = '',
    this.mediaUrls = const [],
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollegeOfficialContentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CollegeOfficialContentModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      section: json['section'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'authorId': authorId,
        'section': section,
        'title': title,
        'body': body,
        'mediaUrls': mediaUrls,
        'isPublished': isPublished,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class FacultyWorkshopModel {
  final String id;
  final String facultyId;
  final String collegeId;
  final String title;
  final String description;
  final DateTime? scheduledAt;
  final String status;
  final DateTime createdAt;

  const FacultyWorkshopModel({
    required this.id,
    required this.facultyId,
    required this.collegeId,
    required this.title,
    this.description = '',
    this.scheduledAt,
    this.status = 'published',
    required this.createdAt,
  });

  factory FacultyWorkshopModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return FacultyWorkshopModel(
      id: docId ?? json['id'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null ? _parseDate(json['scheduledAt']) : null,
      status: json['status'] as String? ?? 'published',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'facultyId': facultyId,
        'collegeId': collegeId,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}

class FacultyResearchModel {
  final String id;
  final String facultyId;
  final String collegeId;
  final String title;
  final String abstract;
  final String? linkUrl;
  final DateTime createdAt;

  const FacultyResearchModel({
    required this.id,
    required this.facultyId,
    required this.collegeId,
    required this.title,
    this.abstract = '',
    this.linkUrl,
    required this.createdAt,
  });

  factory FacultyResearchModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return FacultyResearchModel(
      id: docId ?? json['id'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      abstract: json['abstract'] as String? ?? '',
      linkUrl: json['linkUrl'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'facultyId': facultyId,
        'collegeId': collegeId,
        'title': title,
        'abstract': abstract,
        'linkUrl': linkUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}

class AlumniMentorshipOfferModel {
  final String id;
  final String alumniId;
  final String alumniName;
  final String collegeId;
  final String collegeName;
  final String topic;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  const AlumniMentorshipOfferModel({
    required this.id,
    required this.alumniId,
    this.alumniName = '',
    required this.collegeId,
    this.collegeName = '',
    required this.topic,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
  });

  factory AlumniMentorshipOfferModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AlumniMentorshipOfferModel(
      id: docId ?? json['id'] as String? ?? '',
      alumniId: json['alumniId'] as String? ?? '',
      alumniName: json['alumniName'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alumniId': alumniId,
        'alumniName': alumniName,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'topic': topic,
        'description': description,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}

class AuditLogModel {
  final String id;
  final String action;
  final String actorId;
  final String actorName;
  final String? targetId;
  final String? targetType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.action,
    required this.actorId,
    this.actorName = '',
    this.targetId,
    this.targetType,
    this.metadata = const {},
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AuditLogModel(
      id: docId ?? json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'actorId': actorId,
        'actorName': actorName,
        'targetId': targetId,
        'targetType': targetType,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };
}
