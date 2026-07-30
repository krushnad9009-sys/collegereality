import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/verification/models/verification_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 2, 1, 10, 0);
  final reviewed = DateTime(2026, 2, 3, 14, 30);

  group('VerificationRequestModel JSON', () {
    test('round-trip preserves AI review fields', () {
      final original = VerificationRequestModel(
        id: 'ver-1',
        userId: 'user-1',
        documentType: VerificationConstants.documentCollegeId,
        storagePath: 'verification/user-1/id.pdf',
        contentHash: 'abc123hash',
        status: VerificationConstants.statusPendingReview,
        verificationRole: VerificationConstants.roleStudent,
        collegeId: 'col-1',
        collegeName: 'COEP',
        aiFlags: const ['blurry', 'name_mismatch'],
        aiConfidence: 0.72,
        aiSummary: 'Document readable but name differs slightly.',
        requiresManualReview: true,
        adminNote: 'Awaiting reviewer',
        reviewedBy: 'admin-1',
        createdAt: created,
        reviewedAt: reviewed,
      );
      final restored = VerificationRequestModel.fromJson(original.toJson(), docId: 'ver-1');
      expect(restored.documentType, VerificationConstants.documentCollegeId);
      expect(restored.aiFlags, ['blurry', 'name_mismatch']);
      expect(restored.aiConfidence, 0.72);
      expect(restored.collegeName, 'COEP');
      expect(restored.reviewedAt, reviewed);
      expect(restored.requiresManualReview, isTrue);
    });

    test('fromJson applies defaults for missing fields', () {
      final restored = VerificationRequestModel.fromJson({
        'userId': 'u1',
        'documentType': 'id_card',
        'storagePath': 'path',
        'contentHash': 'hash',
        'createdAt': created.toIso8601String(),
      });
      expect(restored.status, 'pending_review');
      expect(restored.verificationRole, VerificationConstants.roleStudent);
      expect(restored.aiFlags, isEmpty);
      expect(restored.requiresManualReview, isTrue);
    });
  });

  group('DocumentValidationResult', () {
    test('holds validation outcome fields', () {
      const result = DocumentValidationResult(
        confidence: 0.85,
        flags: ['duplicate'],
        summary: 'Possible duplicate upload',
        requiresManualReview: true,
        isDuplicate: true,
      );
      expect(result.isDuplicate, isTrue);
      expect(result.flags, contains('duplicate'));
    });
  });
}
