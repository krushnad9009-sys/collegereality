import '../../../core/constants/rating_parameters.dart';

class ReviewModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String userId;
  final String anonymousAlias;
  final String? course;
  final int? batchYear;
  final Map<String, double> ratings;
  final String textReview;
  final List<String> pros;
  final List<String> cons;
  final int likeCount;
  final bool isVerifiedStudent;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.userId,
    required this.anonymousAlias,
    this.course,
    this.batchYear,
    required this.ratings,
    this.textReview = '',
    this.pros = const [],
    this.cons = const [],
    this.likeCount = 0,
    this.isVerifiedStudent = false,
    this.status = 'published',
    required this.createdAt,
    required this.updatedAt,
  });

  double get overallRating =>
      ratings[RatingParameters.overall] ??
      ratings.values.where((v) => v > 0).fold(0.0, (a, b) => a + b) /
          ratings.values.where((v) => v > 0).length;

  factory ReviewModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final ratingsRaw = json['ratings'] as Map<String, dynamic>? ?? {};
    final ratings = ratingsRaw.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ReviewModel(
      id: docId ?? json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      anonymousAlias: json['anonymousAlias'] as String? ?? 'Anonymous Student',
      course: json['course'] as String?,
      batchYear: (json['batchYear'] as num?)?.toInt(),
      ratings: ratings,
      textReview: json['textReview'] as String? ?? '',
      pros: (json['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cons: (json['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isVerifiedStudent: json['isVerifiedStudent'] as bool? ?? false,
      status: json['status'] as String? ?? 'published',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'userId': userId,
      'anonymousAlias': anonymousAlias,
      'course': course,
      'batchYear': batchYear,
      'ratings': ratings,
      'textReview': textReview,
      'pros': pros,
      'cons': cons,
      'likeCount': likeCount,
      'isVerifiedStudent': isVerifiedStudent,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? collegeId,
    String? collegeName,
    String? userId,
    String? anonymousAlias,
    String? course,
    int? batchYear,
    Map<String, double>? ratings,
    String? textReview,
    List<String>? pros,
    List<String>? cons,
    int? likeCount,
    bool? isVerifiedStudent,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      userId: userId ?? this.userId,
      anonymousAlias: anonymousAlias ?? this.anonymousAlias,
      course: course ?? this.course,
      batchYear: batchYear ?? this.batchYear,
      ratings: ratings ?? this.ratings,
      textReview: textReview ?? this.textReview,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      likeCount: likeCount ?? this.likeCount,
      isVerifiedStudent: isVerifiedStudent ?? this.isVerifiedStudent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
