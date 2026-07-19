class VerificationConstants {
  VerificationConstants._();

  static const roleStudent = 'student';
  static const roleAlumni = 'alumni';

  static const documentCollegeId = 'college_id';
  static const documentBonafide = 'bonafide_certificate';
  static const documentFeeReceipt = 'fee_receipt';
  static const documentAdmissionLetter = 'admission_letter';
  static const documentFinalMarksheet = 'final_year_marksheet';

  static const List<Map<String, String>> studentDocumentTypes = [
    {'id': documentCollegeId, 'label': 'College ID Card'},
    {'id': documentBonafide, 'label': 'Bonafide Certificate'},
  ];

  static const List<Map<String, String>> alumniDocumentTypes = [
    {'id': documentFinalMarksheet, 'label': 'Graduation Marksheet'},
    {'id': documentBonafide, 'label': 'Bonafide Certificate'},
  ];

  static const List<Map<String, String>> documentTypes = [
    ...studentDocumentTypes,
    ...alumniDocumentTypes,
  ];

  static const badgeNone = 'none';
  static const badgeVerifiedStudent = 'verified_student';
  static const badgeVerifiedAlumni = 'verified_alumni';
  static const badgeVerifiedFaculty = 'verified_faculty';

  static const statusIncomplete = 'incomplete';
  static const statusPendingReview = 'pending_review';
  static const statusFlagged = 'flagged';
  static const statusApproved = 'approved';
  static const statusRejected = 'rejected';
  static const statusResubmissionRequested = 'resubmission_requested';

  static const flagDuplicate = 'duplicate_upload';
  static const flagManipulated = 'possible_manipulation';
  static const flagSuspicious = 'suspicious_document';
  static const flagLowQuality = 'low_quality';
  static const flagInvalidFormat = 'invalid_format';

  static const int minFileBytes = 10 * 1024;
  static const int maxFileBytes = 10 * 1024 * 1024;
  static const double autoApproveConfidence = 0.85;

  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  static List<Map<String, String>> documentTypesForRole(String role) {
    if (role == roleAlumni) return alumniDocumentTypes;
    return studentDocumentTypes;
  }

  static String roleLabel(String role) {
    switch (role) {
      case roleAlumni:
        return 'Alumni';
      case roleStudent:
        return 'Current Student';
      default:
        return role;
    }
  }

  static String documentLabel(String type) {
    return documentTypes
        .firstWhere(
          (d) => d['id'] == type,
          orElse: () => {'id': type, 'label': type},
        )['label']!;
  }

  static String badgeLabel(String badge) {
    switch (badge) {
      case badgeVerifiedStudent:
        return 'Verified Student';
      case badgeVerifiedAlumni:
        return 'Verified Alumni';
      case badgeVerifiedFaculty:
        return 'Verified Faculty';
      default:
        return '';
    }
  }

  static bool isAlumniDocument(String documentType) {
    return documentType == documentFinalMarksheet;
  }

  static bool isApprovedStudentOrAlumni(String? badge, String? status) {
    if (status != statusApproved) return false;
    return badge == badgeVerifiedStudent || badge == badgeVerifiedAlumni;
  }
}
