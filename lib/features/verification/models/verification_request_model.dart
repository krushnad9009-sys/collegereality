import '../../../core/constants/verification_constants.dart';

class VerificationRequestModel {
  final String id;
  final String userId;
  final String documentType;
  final String storagePath;
  final String contentHash;

  /// Multi-document submissions (the "Student Verification" card in Edit
  /// Profile requires 2). [documentType] / [storagePath] / [contentHash]
  /// above stay populated with the FIRST entry so the single-document AI
  /// agent and admin review UI keep working unchanged; these arrays carry
  /// the full set for a human reviewer. Empty for legacy single-doc
  /// submissions.
  final List<String> documentTypes;
  final List<String> storagePaths;
  final List<String> contentHashes;

  final String status;
  final String verificationRole;
  final String? collegeId;
  final String? collegeName;
  final List<String> aiFlags;
  final double aiConfidence;
  final String aiSummary;
  final bool requiresManualReview;
  final String? adminNote;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  // ── AI Automated Verification Agent (Cloud Functions) ────────────────
  /// 'accept' | 'reject' | 'flag' — null until the agent has run.
  final String? aiDecision;

  /// 'pending' | 'processing' | 'done' | 'error'.
  final String aiStatus;

  /// Redacted fields the agent read off the document
  /// (name / college / idNumberMasked / documentKind).
  final Map<String, dynamic> aiExtracted;

  /// Per-signal sub-scores the agent produced (clarity, tamper, nameMatch…).
  final Map<String, dynamic> aiChecks;

  final String? aiModel;
  final DateTime? aiReviewedAt;

  /// True once the agent has produced any verdict.
  bool get aiReviewed => aiReviewedAt != null;

  const VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.storagePath,
    required this.contentHash,
    this.documentTypes = const [],
    this.storagePaths = const [],
    this.contentHashes = const [],
    required this.status,
    this.verificationRole = VerificationConstants.roleStudent,
    this.collegeId,
    this.collegeName,
    this.aiFlags = const [],
    this.aiConfidence = 0,
    this.aiSummary = '',
    this.requiresManualReview = true,
    this.adminNote,
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
    this.aiDecision,
    this.aiStatus = 'pending',
    this.aiExtracted = const {},
    this.aiChecks = const {},
    this.aiModel,
    this.aiReviewedAt,
  });

  factory VerificationRequestModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return VerificationRequestModel(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      documentTypes:
          (json['documentTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      storagePaths:
          (json['storagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      contentHashes:
          (json['contentHashes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'pending_review',
      verificationRole:
          json['verificationRole'] as String? ??
          VerificationConstants.roleStudent,
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
      aiFlags:
          (json['aiFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0,
      aiSummary: json['aiSummary'] as String? ?? '',
      requiresManualReview: json['requiresManualReview'] as bool? ?? true,
      adminNote: json['adminNote'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      aiDecision: json['aiDecision'] as String?,
      aiStatus: json['aiStatus'] as String? ?? 'pending',
      aiExtracted:
          (json['aiExtracted'] as Map?)?.cast<String, dynamic>() ?? const {},
      aiChecks: (json['aiChecks'] as Map?)?.cast<String, dynamic>() ?? const {},
      aiModel: json['aiModel'] as String?,
      aiReviewedAt: DateTime.tryParse(json['aiReviewedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'documentType': documentType,
    'storagePath': storagePath,
    'contentHash': contentHash,
    'documentTypes': documentTypes,
    'storagePaths': storagePaths,
    'contentHashes': contentHashes,
    'status': status,
    'verificationRole': verificationRole,
    'collegeId': collegeId,
    'collegeName': collegeName,
    'aiFlags': aiFlags,
    'aiConfidence': aiConfidence,
    'aiSummary': aiSummary,
    'requiresManualReview': requiresManualReview,
    'adminNote': adminNote,
    'reviewedBy': reviewedBy,
    'createdAt': createdAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'aiDecision': aiDecision,
    'aiStatus': aiStatus,
    'aiExtracted': aiExtracted,
    'aiChecks': aiChecks,
    'aiModel': aiModel,
    'aiReviewedAt': aiReviewedAt?.toIso8601String(),
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
