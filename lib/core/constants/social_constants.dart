class SocialConstants {
  SocialConstants._();

  static const int defaultPageSize = 20;
  static const int maxMessagesPerMinute = 15;
  // Cap on the live chat listener (watchMessages) so an old, very long
  // conversation doesn't stream/re-listen its entire history forever.
  // Older messages are still reachable via fetchMessagesPage.
  static const int liveMessageWindow = 200;
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
