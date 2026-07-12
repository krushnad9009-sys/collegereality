class VerificationRequestModel {
  final String id;
  final String userId;
  final String documentType;
  final String storagePath;
  final String contentHash;
  final String status;
  final List<String> aiFlags;
  final double aiConfidence;
  final String aiSummary;
  final bool requiresManualReview;
  final String? adminNote;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.storagePath,
    required this.contentHash,
    required this.status,
    this.aiFlags = const [],
    this.aiConfidence = 0,
    this.aiSummary = '',
    this.requiresManualReview = true,
    this.adminNote,
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json,
      {String? docId}) {
    return VerificationRequestModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      aiFlags: (json['aiFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0,
      aiSummary: json['aiSummary'] as String? ?? '',
      requiresManualReview: json['requiresManualReview'] as bool? ?? true,
      adminNote: json['adminNote'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'documentType': documentType,
        'storagePath': storagePath,
        'contentHash': contentHash,
        'status': status,
        'aiFlags': aiFlags,
        'aiConfidence': aiConfidence,
        'aiSummary': aiSummary,
        'requiresManualReview': requiresManualReview,
        'adminNote': adminNote,
        'reviewedBy': reviewedBy,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };
}

class DocumentValidationResult {
  final double confidence;
  final List<String> flags;
  final String summary;
  final bool requiresManualReview;
  final bool isDuplicate;

  const DocumentValidationResult({
    required this.confidence,
    required this.flags,
    required this.summary,
    required this.requiresManualReview,
    this.isDuplicate = false,
  });
}
