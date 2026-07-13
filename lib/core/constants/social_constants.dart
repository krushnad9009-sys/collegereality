class SocialConstants {
  SocialConstants._();

  static const int defaultPageSize = 20;
  static const int maxMessagesPerMinute = 15;
  static const int maxPostsPerHour = 10;

  static const String contentStatusVisible = 'visible';
  static const String contentStatusHidden = 'hidden';
  static const String contentStatusSpam = 'spam';

  static const String feedTypeCampusPost = 'campus_post';
  static const String feedTypeCollegeChat = 'college_chat';
  static const String feedTypeQaThread = 'qa_thread';
  static const String feedTypeQuestion = 'college_question';

  static const String moderationFlagSpam = 'spam';
  static const String moderationFlagOffensive = 'offensive';
  static const String moderationFlagReported = 'reported';
}
