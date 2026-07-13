/// College Reality ecosystem workflows — requests, edits, claims, official content.
class EcosystemConstants {
  EcosystemConstants._();

  // Workflow statuses
  static const String statusPending = 'pending_review';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusApplied = 'applied';

  // College data report types (C)
  static const String reportWrongFees = 'wrong_fees';
  static const String reportWrongPlacement = 'wrong_placement';
  static const String reportWrongAddress = 'wrong_address';
  static const String reportWrongPhone = 'wrong_phone';
  static const String reportWrongWebsite = 'wrong_website';
  static const String reportWrongPhotos = 'wrong_photos';
  static const String reportDuplicateCollege = 'duplicate_college';
  static const String reportSpam = 'spam';

  static const List<Map<String, String>> dataReportTypes = [
    {'id': reportWrongFees, 'label': 'Wrong fees'},
    {'id': reportWrongPlacement, 'label': 'Wrong placement data'},
    {'id': reportWrongAddress, 'label': 'Wrong address'},
    {'id': reportWrongPhone, 'label': 'Wrong phone number'},
    {'id': reportWrongWebsite, 'label': 'Wrong website'},
    {'id': reportWrongPhotos, 'label': 'Wrong photos'},
    {'id': reportDuplicateCollege, 'label': 'Duplicate college'},
    {'id': reportSpam, 'label': 'Spam / fake listing'},
  ];

  // Official dashboard sections (G)
  static const String sectionNotice = 'notice';
  static const String sectionAdmission = 'admission';
  static const String sectionPlacement = 'placement';
  static const String sectionScholarship = 'scholarship';
  static const String sectionEvent = 'event';
  static const String sectionGallery = 'gallery';
  static const String sectionHostel = 'hostel';
  static const String sectionRecruiter = 'recruiter';
  static const String sectionCourse = 'course';

  static const List<Map<String, String>> officialSections = [
    {'id': sectionNotice, 'label': 'Notice Board'},
    {'id': sectionAdmission, 'label': 'Admissions'},
    {'id': sectionPlacement, 'label': 'Placements'},
    {'id': sectionScholarship, 'label': 'Scholarships'},
    {'id': sectionEvent, 'label': 'Events'},
    {'id': sectionGallery, 'label': 'Gallery'},
    {'id': sectionHostel, 'label': 'Hostel'},
    {'id': sectionRecruiter, 'label': 'Recruiters'},
    {'id': sectionCourse, 'label': 'Courses'},
  ];

  // Audit actions (K)
  static const String auditCollegeRequest = 'college_request';
  static const String auditEditSuggestion = 'edit_suggestion';
  static const String auditDataReport = 'data_report';
  static const String auditCollegeClaim = 'college_claim';
  static const String auditFacultyVerification = 'faculty_verification';
  static const String auditOfficialContent = 'official_content';
  static const String auditRoleChange = 'role_change';
  static const String auditModeration = 'moderation';

  // Notification types (L)
  static const String notifVerificationUpdate = 'verification_update';
  static const String notifCollegeRequestUpdate = 'college_request_update';
  static const String notifEditSuggestionUpdate = 'edit_suggestion_update';
  static const String notifClaimUpdate = 'college_claim_update';
  static const String notifOfficialNotice = 'official_notice';

  static const int pageSize = 20;
  static const int maxEditHistory = 50;

  static String reportTypeLabel(String type) {
    return dataReportTypes
        .firstWhere(
          (e) => e['id'] == type,
          orElse: () => {'id': type, 'label': type},
        )['label']!;
  }

  static String sectionLabel(String section) {
    return officialSections
        .firstWhere(
          (e) => e['id'] == section,
          orElse: () => {'id': section, 'label': section},
        )['label']!;
  }
}
