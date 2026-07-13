import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/student_life_constants.dart';

class CampusEventModel {
  final String id;
  final String title;
  final String collegeId;
  final String collegeName;
  final String category;
  final String description;
  final String location;
  final DateTime startAt;
  final DateTime endAt;
  final String posterUrl;
  final List<String> galleryUrls;
  final String searchText;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampusEventModel({
    required this.id,
    required this.title,
    required this.collegeId,
    required this.collegeName,
    required this.category,
    this.description = '',
    this.location = '',
    required this.startAt,
    required this.endAt,
    this.posterUrl = '',
    this.galleryUrls = const [],
    this.searchText = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUpcoming => startAt.isAfter(DateTime.now());

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory CampusEventModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CampusEventModel(
      id: docId ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      category: json['category'] as String? ?? StudentLifeConstants.eventTechnical,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startAt: _parseDate(json['startAt']),
      endAt: _parseDate(json['endAt']),
      posterUrl: json['posterUrl'] as String? ?? '',
      galleryUrls: (json['galleryUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'category': category,
        'description': description,
        'location': location,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'posterUrl': posterUrl,
        'galleryUrls': galleryUrls,
        'searchText': searchText,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class StudentClubModel {
  final String id;
  final String name;
  final String collegeId;
  final String collegeName;
  final String clubType;
  final String description;
  final String facultyCoordinator;
  final List<String> studentCoordinators;
  final int membersCount;
  final String searchText;
  final bool isActive;
  final DateTime updatedAt;

  const StudentClubModel({
    required this.id,
    required this.name,
    required this.collegeId,
    required this.collegeName,
    required this.clubType,
    this.description = '',
    this.facultyCoordinator = '',
    this.studentCoordinators = const [],
    this.membersCount = 0,
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

  factory StudentClubModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return StudentClubModel(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      clubType: json['clubType'] as String? ?? StudentLifeConstants.clubTechnical,
      description: json['description'] as String? ?? '',
      facultyCoordinator: json['facultyCoordinator'] as String? ?? '',
      studentCoordinators:
          (json['studentCoordinators'] as List<dynamic>?)?.cast<String>() ?? const [],
      membersCount: (json['membersCount'] as num?)?.toInt() ?? 0,
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'clubType': clubType,
        'description': description,
        'facultyCoordinator': facultyCoordinator,
        'studentCoordinators': studentCoordinators,
        'membersCount': membersCount,
        'searchText': searchText,
        'isActive': isActive,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class CompetitionWinnerModel {
  final String name;
  final String position;
  final String collegeName;

  const CompetitionWinnerModel({
    required this.name,
    required this.position,
    this.collegeName = '',
  });

  factory CompetitionWinnerModel.fromJson(Map<String, dynamic> json) {
    return CompetitionWinnerModel(
      name: json['name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'position': position,
        'collegeName': collegeName,
      };
}

class CompetitionModel {
  final String id;
  final String title;
  final String collegeId;
  final String collegeName;
  final String scope;
  final String description;
  final String prizeDetails;
  final DateTime registrationDeadline;
  final List<CompetitionWinnerModel> winners;
  final List<String> certificateUrls;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final String searchText;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompetitionModel({
    required this.id,
    required this.title,
    required this.collegeId,
    required this.collegeName,
    required this.scope,
    this.description = '',
    this.prizeDetails = '',
    required this.registrationDeadline,
    this.winners = const [],
    this.certificateUrls = const [],
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.searchText = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRegistrationOpen => registrationDeadline.isAfter(DateTime.now());

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory CompetitionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CompetitionModel(
      id: docId ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      scope: json['scope'] as String? ?? StudentLifeConstants.scopeCollege,
      description: json['description'] as String? ?? '',
      prizeDetails: json['prizeDetails'] as String? ?? '',
      registrationDeadline: _parseDate(json['registrationDeadline']),
      winners: (json['winners'] as List<dynamic>?)
              ?.map((e) => CompetitionWinnerModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      certificateUrls: (json['certificateUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      videoUrls: (json['videoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      searchText: json['searchText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'scope': scope,
        'description': description,
        'prizeDetails': prizeDetails,
        'registrationDeadline': registrationDeadline.toIso8601String(),
        'winners': winners.map((w) => w.toJson()).toList(),
        'certificateUrls': certificateUrls,
        'photoUrls': photoUrls,
        'videoUrls': videoUrls,
        'searchText': searchText,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class StudentCommunityModel {
  final String id;
  final String name;
  final String collegeId;
  final String collegeName;
  final String communityType;
  final String branchOrYear;
  final String description;
  final bool verifiedStudentsOnly;
  final bool isActive;
  final DateTime updatedAt;

  const StudentCommunityModel({
    required this.id,
    required this.name,
    required this.collegeId,
    required this.collegeName,
    required this.communityType,
    required this.branchOrYear,
    this.description = '',
    this.verifiedStudentsOnly = true,
    this.isActive = true,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory StudentCommunityModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return StudentCommunityModel(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      communityType: json['communityType'] as String? ?? StudentLifeConstants.communityBranch,
      branchOrYear: json['branchOrYear'] as String? ?? '',
      description: json['description'] as String? ?? '',
      verifiedStudentsOnly: json['verifiedStudentsOnly'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'communityType': communityType,
        'branchOrYear': branchOrYear,
        'description': description,
        'verifiedStudentsOnly': verifiedStudentsOnly,
        'isActive': isActive,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class PollOptionModel {
  final String id;
  final String label;
  final int voteCount;

  const PollOptionModel({
    required this.id,
    required this.label,
    this.voteCount = 0,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'voteCount': voteCount,
      };
}

class StudentCommunityPostModel {
  final String id;
  final String communityId;
  final String authorId;
  final String authorDisplayName;
  final bool isVerifiedStudent;
  final String postType;
  final String content;
  final List<String> imageUrls;
  final List<String> pdfUrls;
  final String pollQuestion;
  final List<PollOptionModel> pollOptions;
  final DateTime? pollEndsAt;
  final String status;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentCommunityPostModel({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorDisplayName,
    this.isVerifiedStudent = false,
    required this.postType,
    this.content = '',
    this.imageUrls = const [],
    this.pdfUrls = const [],
    this.pollQuestion = '',
    this.pollOptions = const [],
    this.pollEndsAt,
    this.status = StudentLifeConstants.statusPublished,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPoll => postType == StudentLifeConstants.postPoll;
  bool get isAnnouncement => postType == StudentLifeConstants.postAnnouncement;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory StudentCommunityPostModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return StudentCommunityPostModel(
      id: docId ?? json['id'] as String? ?? '',
      communityId: json['communityId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Student',
      isVerifiedStudent: json['isVerifiedStudent'] as bool? ?? false,
      postType: json['postType'] as String? ?? StudentLifeConstants.postDiscussion,
      content: json['content'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      pdfUrls: (json['pdfUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      pollQuestion: json['pollQuestion'] as String? ?? '',
      pollOptions: (json['pollOptions'] as List<dynamic>?)
              ?.map((e) => PollOptionModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      pollEndsAt: json['pollEndsAt'] != null ? _parseDate(json['pollEndsAt']) : null,
      status: json['status'] as String? ?? StudentLifeConstants.statusPublished,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'communityId': communityId,
        'authorId': authorId,
        'authorDisplayName': authorDisplayName,
        'isVerifiedStudent': isVerifiedStudent,
        'postType': postType,
        'content': content,
        'imageUrls': imageUrls,
        'pdfUrls': pdfUrls,
        'pollQuestion': pollQuestion,
        'pollOptions': pollOptions.map((o) => o.toJson()).toList(),
        if (pollEndsAt != null) 'pollEndsAt': pollEndsAt!.toIso8601String(),
        'status': status,
        'commentCount': commentCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class StudentCommunityCommentModel {
  final String id;
  final String postId;
  final String communityId;
  final String authorId;
  final String authorDisplayName;
  final bool isVerifiedStudent;
  final String content;
  final String status;
  final DateTime createdAt;

  const StudentCommunityCommentModel({
    required this.id,
    required this.postId,
    required this.communityId,
    required this.authorId,
    required this.authorDisplayName,
    this.isVerifiedStudent = false,
    required this.content,
    this.status = StudentLifeConstants.statusPublished,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory StudentCommunityCommentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return StudentCommunityCommentModel(
      id: docId ?? json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      communityId: json['communityId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? 'Student',
      isVerifiedStudent: json['isVerifiedStudent'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? StudentLifeConstants.statusPublished,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'communityId': communityId,
        'authorId': authorId,
        'authorDisplayName': authorDisplayName,
        'isVerifiedStudent': isVerifiedStudent,
        'content': content,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
