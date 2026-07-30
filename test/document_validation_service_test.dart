import 'dart:typed_data';

import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/features/verification/services/document_validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(int length, {int fill = 7}) =>
    Uint8List.fromList(List<int>.filled(length, fill));

Uint8List _varied(int length) =>
    Uint8List.fromList(List<int>.generate(length, (i) => i % 251));

void main() {
  final service = DocumentValidationService();

  test('computeHash is stable', () {
    final a = service.computeHash(_bytes(100));
    final b = service.computeHash(_bytes(100));
    expect(a, b);
    expect(a.length, 64);
  });

  test('rejects tiny and oversized files', () async {
    final tiny = await service.validate(
      bytes: _bytes(10),
      fileName: 'id.pdf',
      documentType: VerificationConstants.documentCollegeId,
      isDuplicateHash: (_) async => false,
    );
    expect(tiny.flags, contains(VerificationConstants.flagLowQuality));
    expect(tiny.requiresManualReview, isTrue);

    final huge = await service.validate(
      bytes: _bytes(VerificationConstants.maxFileBytes + 1),
      fileName: 'id.pdf',
      documentType: VerificationConstants.documentCollegeId,
      isDuplicateHash: (_) async => false,
    );
    expect(huge.flags, contains(VerificationConstants.flagInvalidFormat));
  });

  test('rejects bad extension and duplicates', () async {
    final badExt = await service.validate(
      bytes: _varied(40 * 1024),
      fileName: 'id.exe',
      documentType: VerificationConstants.documentCollegeId,
      isDuplicateHash: (_) async => false,
    );
    expect(badExt.flags, contains(VerificationConstants.flagInvalidFormat));

    final dup = await service.validate(
      bytes: _varied(40 * 1024),
      fileName: 'id.pdf',
      documentType: VerificationConstants.documentCollegeId,
      isDuplicateHash: (_) async => true,
    );
    expect(dup.isDuplicate, isTrue);
    expect(dup.flags, contains(VerificationConstants.flagDuplicate));
  });

  test('flags manipulated and suspicious names', () async {
    final edited = await service.validate(
      bytes: _varied(40 * 1024),
      fileName: 'photoshop_id.pdf',
      documentType: VerificationConstants.documentCollegeId,
      isDuplicateHash: (_) async => false,
    );
    expect(edited.flags, contains(VerificationConstants.flagManipulated));

    final shot = await service.validate(
      bytes: _varied(40 * 1024),
      fileName: 'screenshot_marksheet.pdf',
      documentType: VerificationConstants.documentFinalMarksheet,
      isDuplicateHash: (_) async => false,
    );
    expect(shot.flags, contains(VerificationConstants.flagSuspicious));
  });

  test('clean document gets high confidence', () async {
    final ok = await service.validate(
      bytes: _varied(50 * 1024),
      fileName: 'college_id.pdf',
      documentType: VerificationConstants.documentCollegeId,
      isDuplicateHash: (_) async => false,
    );
    expect(ok.confidence, greaterThan(0.7));
    expect(ok.flags, isEmpty);
  });
}