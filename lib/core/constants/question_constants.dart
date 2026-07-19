class QuestionConstants {
  QuestionConstants._();

  static const int pageSize = 20;
  static const int maxTitleLength = 200;
  static const int maxBodyLength = 2000;
  static const int maxAnswerLength = 3000;

  /// Minimum minutes between questions from the same user at one college.
  static const int questionCooldownMinutes = 5;

  /// Minimum minutes between answers from the same user.
  static const int answerCooldownMinutes = 2;

  /// Max questions per user per college per day.
  static const int maxQuestionsPerDayPerCollege = 10;

  /// Max answers per user per day.
  static const int maxAnswersPerDay = 25;

  static const String statusPublished = 'published';
  static const String statusHidden = 'hidden';
  static const String statusRemoved = 'removed';

  static const String reportStatusOpen = 'open';
  static const String reportStatusReviewed = 'reviewed';
  static const String reportStatusActionTaken = 'action_taken';

  static const String filterLatest = 'latest';
  static const String filterMostHelpful = 'most_helpful';
  static const String filterUnanswered = 'unanswered';

  static const String voteUp = 'up';
  static const String voteDown = 'down';

  static const String reportTypeQuestion = 'question';
  static const String reportTypeAnswer = 'answer';
}
