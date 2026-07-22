class EngagementConstants {
  EngagementConstants._();

  static const String metaEngagementSeededDoc = 'engagementSeeded';

  // Notification types
  static const String typeNewReview = 'new_review';
  static const String typeNewAnswer = 'new_answer';
  static const String typeNewChatMessage = 'new_chat_message';
  static const String typeCollegeUpdate = 'college_update';
  static const String typePlacementUpdate = 'placement_update';
  static const String typeScholarshipUpdate = 'scholarship_update';
  static const String typeEventReminder = 'event_reminder';
  static const String typeAdmissionReminder = 'admission_reminder';
  static const String typeFeesChange = 'fees_change';
  static const String typePlacementStatsChange = 'placement_stats_change';
  static const String typeScholarshipOpen = 'scholarship_open';
  static const String typeAdmissionStart = 'admission_start';
  static const String typeAdmissionDeadline = 'admission_deadline';
  static const String typeNewEvent = 'new_event';
  static const String typeNewJob = 'new_job';
  static const String typeNewInternship = 'new_internship';
  static const String typeApplicationUpdate = 'application_update';
  static const String typeVerificationUpdate = 'verification_update';
  static const String typeCollegeRequestUpdate = 'college_request_update';
  static const String typeEditSuggestionUpdate = 'edit_suggestion_update';
  static const String typeClaimUpdate = 'college_claim_update';
  static const String typeOfficialNotice = 'official_notice';
  static const String typeCommunityComment = 'community_comment';
  static const String typeCommunityReply = 'community_reply';
  static const String typeReviewApproved = 'review_approved';
  static const String typeReviewComment = 'review_comment';
  static const String typeCommunityPost = 'community_post';
  static const String typeAdminAnnouncement = 'admin_announcement';

  static const String categoryAdmin = 'admin';

  static const String categoryReviews = 'reviews';
  static const String categoryQuestions = 'questions';
  static const String categoryChat = 'chat';
  static const String categoryColleges = 'colleges';
  static const String categoryPlacements = 'placements';
  static const String categoryScholarships = 'scholarships';
  static const String categoryEvents = 'events';
  static const String categoryAdmission = 'admission';
  static const String categoryCareers = 'careers';
  static const String categoryCommunity = 'community';

  // Calendar categories
  static const String calendarCapRound = 'cap_round';
  static const String calendarCounselling = 'counselling';
  static const String calendarDocVerification = 'document_verification';
  static const String calendarSeatAllotment = 'seat_allotment';
  static const String calendarFeePayment = 'fee_payment';
  static const String calendarHostelAdmission = 'hostel_admission';
  static const String calendarExamDate = 'exam_date';
  static const String calendarResultDate = 'result_date';

  static const List<String> notificationCategories = [
    categoryReviews,
    categoryQuestions,
    categoryChat,
    categoryColleges,
    categoryPlacements,
    categoryScholarships,
    categoryEvents,
    categoryAdmission,
    categoryCareers,
    categoryCommunity,
    categoryAdmin,
  ];

  static String calendarCategoryLabel(String category) {
    switch (category) {
      case calendarCapRound:
        return 'CAP Round';
      case calendarCounselling:
        return 'Counselling';
      case calendarDocVerification:
        return 'Document Verification';
      case calendarSeatAllotment:
        return 'Seat Allotment';
      case calendarFeePayment:
        return 'Fee Payment';
      case calendarHostelAdmission:
        return 'Hostel Admission';
      case calendarExamDate:
        return 'Exam Date';
      case calendarResultDate:
        return 'Result Date';
      default:
        return category;
    }
  }

  static String notificationTypeLabel(String type) {
    switch (type) {
      case typeNewReview:
        return 'New Review';
      case typeNewAnswer:
        return 'New Answer';
      case typeNewChatMessage:
        return 'New Message';
      case typeCollegeUpdate:
        return 'College Update';
      case typePlacementUpdate:
        return 'Placement Update';
      case typeScholarshipUpdate:
        return 'Scholarship Update';
      case typeEventReminder:
        return 'Event Reminder';
      case typeAdmissionReminder:
        return 'Admission Reminder';
      case typeFeesChange:
        return 'Fees Changed';
      case typePlacementStatsChange:
        return 'Placement Stats';
      case typeScholarshipOpen:
        return 'Scholarship Open';
      case typeAdmissionStart:
        return 'Admission Started';
      case typeAdmissionDeadline:
        return 'Admission Deadline';
      case typeNewEvent:
        return 'New Event';
      case typeNewJob:
        return 'New Job';
      case typeNewInternship:
        return 'New Internship';
      case typeApplicationUpdate:
        return 'Application Update';
      case typeVerificationUpdate:
        return 'Verification Update';
      case typeReviewApproved:
        return 'Review Approved';
      case typeReviewComment:
        return 'Review Interaction';
      case typeCommunityPost:
        return 'Community Post';
      case typeCommunityComment:
        return 'Community Comment';
      case typeCommunityReply:
        return 'Community Reply';
      case typeAdminAnnouncement:
        return 'Admin Announcement';
      default:
        return type;
    }
  }
}
