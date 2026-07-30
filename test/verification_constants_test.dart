import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document types and labels exist', () {
    expect(VerificationConstants.documentTypesForRole('student'), isNotEmpty);
    expect(VerificationConstants.allowedExtensions, contains('pdf'));
    expect(VerificationConstants.minFileBytes, greaterThan(0));
    expect(VerificationConstants.isAlumniDocument(VerificationConstants.documentFinalMarksheet), isTrue);
  });

  test('approval helpers', () {
    expect(
      VerificationConstants.isApprovedStudentOrAlumni(
        VerificationConstants.badgeVerifiedStudent,
        VerificationConstants.statusApproved,
      ),
      isTrue,
    );
    expect(
      VerificationConstants.isApprovedStudentOrAlumni(
        VerificationConstants.badgeNone,
        VerificationConstants.statusApproved,
      ),
      isFalse,
    );
  });
}