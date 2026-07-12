// Manual JSON serialization without code generation

class UserModel {
  final String uid;
  final String email;
  final String? phone;
  final String? displayName;
  final String? photoURL;
  final String userType;
  final bool isVerified;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? collegeId;
  final String? collegeName;
  final String? course;
  final int? batchYear;
  final List<String> favoriteCollegeIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.uid,
    required this.email,
    this.phone,
    this.displayName,
    this.photoURL,
    this.userType = 'student',
    this.isVerified = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.collegeId,
    this.collegeName,
    this.course,
    this.batchYear,
    this.favoriteCollegeIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      userType: json['userType'] as String? ?? 'student',
      isVerified: json['isVerified'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
      course: json['course'] as String?,
      batchYear: json['batchYear'] as int?,
      favoriteCollegeIds: (json['favoriteCollegeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt'] as DateTime
          : DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType,
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'course': course,
      'batchYear': batchYear,
      'favoriteCollegeIds': favoriteCollegeIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phone,
    String? displayName,
    String? photoURL,
    String? userType,
    bool? isVerified,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? collegeId,
    String? collegeName,
    String? course,
    int? batchYear,
    List<String>? favoriteCollegeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      course: course ?? this.course,
      batchYear: batchYear ?? this.batchYear,
      favoriteCollegeIds: favoriteCollegeIds ?? this.favoriteCollegeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
