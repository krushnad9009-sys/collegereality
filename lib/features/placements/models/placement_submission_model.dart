import '../../../core/constants/placement_constants.dart';

class PlacementSubmissionModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String userId;
  final String companyName;
  final String jobRole;
  final double packageLpa;
  final String employmentType;
  final int year;
  final String? branch;
  final String status;
  final bool isVerifiedStudent;
  final String? adminNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlacementSubmissionModel({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.userId,
    required this.companyName,
    required this.jobRole,
    required this.packageLpa,
    required this.employmentType,
    required this.year,
    this.branch,
    this.status = PlacementConstants.statusPending,
    this.isVerifiedStudent = true,
    this.adminNote,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == PlacementConstants.statusApproved;
  bool get isPending => status == PlacementConstants.statusPending;
  bool get isFullTime => employmentType == PlacementConstants.typeFullTime;
  bool get isInternship => employmentType == PlacementConstants.typeInternship;

  String get employmentLabel =>
      isFullTime ? 'Full-time' : 'Internship';

  factory PlacementSubmissionModel.fromJson(Map<String, dynamic> json) {
    return PlacementSubmissionModel(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      jobRole: json['jobRole'] as String? ?? '',
      packageLpa: (json['packageLpa'] as num?)?.toDouble() ?? 0,
      employmentType: json['employmentType'] as String? ??
          PlacementConstants.typeFullTime,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      branch: json['branch'] as String?,
      status: json['status'] as String? ?? PlacementConstants.statusPending,
      isVerifiedStudent: json['isVerifiedStudent'] as bool? ?? true,
      adminNote: json['adminNote'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'userId': userId,
        'companyName': companyName,
        'jobRole': jobRole,
        'packageLpa': packageLpa,
        'employmentType': employmentType,
        'year': year,
        'branch': branch,
        'status': status,
        'isVerifiedStudent': isVerifiedStudent,
        'adminNote': adminNote,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  PlacementSubmissionModel copyWith({
    String? status,
    String? adminNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return PlacementSubmissionModel(
      id: id,
      collegeId: collegeId,
      collegeName: collegeName,
      userId: userId,
      companyName: companyName,
      jobRole: jobRole,
      packageLpa: packageLpa,
      employmentType: employmentType,
      year: year,
      branch: branch,
      status: status ?? this.status,
      isVerifiedStudent: isVerifiedStudent,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
