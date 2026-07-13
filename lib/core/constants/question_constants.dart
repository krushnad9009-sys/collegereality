class QuestionConstants {
  QuestionConstants._();

  static const int pageSize = 20;
  static const int maxTitleLength = 200;
  static const int maxBodyLength = 2000;
  static const int maxAnswerLength = 3000;

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
