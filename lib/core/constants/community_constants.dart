class CommunityConstants {
  CommunityConstants._();

  static const typePrivate = 'private';
  static const typeCollege = 'college';
  static const typeBranch = 'branch';
  static const typeAskSeniors = 'ask_seniors';
  static const typeQa = 'qa';

  static const messageText = 'text';
  static const messageEmoji = 'emoji';
  static const messageImage = 'image';
  static const messagePdf = 'pdf';

  static const reportStatusOpen = 'open';
  static const reportStatusReviewed = 'reviewed';
  static const reportStatusActionTaken = 'action_taken';

  static const int maxAttachmentBytes = 8 * 1024 * 1024;
  static const Duration typingTimeout = Duration(seconds: 5);
  static const Duration presenceHeartbeat = Duration(seconds: 30);

  static String roomTitle(String type) {
    switch (type) {
      case typeCollege:
        return 'College Discussion';
      case typeBranch:
        return 'Branch Discussion';
      case typeAskSeniors:
        return 'Ask Seniors';
      case typeQa:
        return 'Student Q&A';
      default:
        return 'Chat';
    }
  }
}
