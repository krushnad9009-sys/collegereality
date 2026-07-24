class QuestionConstants {
  QuestionConstants._();

  static const int pageSize = 20;
  static const int maxTitleLength = 200;
  static const int maxBodyLength = 2000;
  static const int maxAnswerLength = 3000;
  static const int maxReplyLength = 1500;
  static const int maxImagesPerPost = 4;
  static const int cacheMaxQuestions = 50;

  static const int questionCooldownMinutes = 5;
  static const int answerCooldownMinutes = 2;
  static const int replyCooldownMinutes = 1;
  static const int maxQuestionsPerDayPerCollege = 10;
  static const int maxAnswersPerDay = 25;
  static const int maxRepliesPerDay = 40;

  static const String statusPublished = 'published';
  static const String statusHidden = 'hidden';
  static const String statusRemoved = 'removed';

  static const String reportStatusOpen = 'open';
  static const String reportStatusReviewed = 'reviewed';
  static const String reportStatusActionTaken = 'action_taken';

  static const String filterLatest = 'latest';
  static const String filterMostHelpful = 'most_helpful';
  static const String filterMostUpvoted = 'most_upvoted';
  static const String filterUnanswered = 'unanswered';

  static const String categoryAll = 'all';
  static const String categoryDepartment = 'department';
  static const String categoryCourse = 'course';
  static const String categoryYear = 'year';
  static const String categoryHostel = 'hostel';
  static const String categoryPlacement = 'placement';
  static const String categoryFaculty = 'faculty';
  static const String categoryFees = 'fees';
  static const String categoryAdmission = 'admission';

  static const List<String> allCategories = [
    categoryAll,
    categoryDepartment,
    categoryCourse,
    categoryYear,
    categoryHostel,
    categoryPlacement,
    categoryFaculty,
    categoryFees,
    categoryAdmission,
  ];

  static const String voteUp = 'up';
  static const String voteDown = 'down';

  static const String reportTypeQuestion = 'question';
  static const String reportTypeAnswer = 'answer';
  static const String reportTypeReply = 'reply';

  static String categoryLabel(String category) {
    switch (category) {
      case categoryDepartment:
        return 'Department';
      case categoryCourse:
        return 'Course';
      case categoryYear:
        return 'Year / Batch';
      case categoryHostel:
        return 'Hostel';
      case categoryPlacement:
        return 'Placement';
      case categoryFaculty:
        return 'Faculty';
      case categoryFees:
        return 'Fees';
      case categoryAdmission:
        return 'Admission';
      case categoryAll:
        return 'All Topics';
      default:
        return category;
    }
  }

  static String sortLabel(String sort) {
    switch (sort) {
      case filterMostHelpful:
        return 'Most Helpful';
      case filterMostUpvoted:
        return 'Most Upvoted';
      case filterUnanswered:
        return 'Unanswered';
      default:
        return 'Latest';
    }
  }
}
