class AiAssistantConstants {
  AiAssistantConstants._();

  static const int maxRecommendations = 10;
  static const int maxCompareColleges = 3;
  static const int candidateFetchLimit = 48;
  static const int maxConversationTurns = 30;
  static const Duration dataCacheTtl = Duration(minutes: 15);
  static const int maxReviewsPerFetch = 8;
  static const int maxQuestionsPerFetch = 5;
  static const int maxAnswersPerQuestion = 3;
  static const int maxVerifiedAnswersTotal = 8;
  static const int maxCommunityPostsPerFetch = 5;
  static const int maxSourceExcerptLength = 140;

  // Intentionally no example/suggested-question lists here. The AI
  // Assistant must never auto-generate or pre-populate any question --
  // the user always decides what to ask via the input bar.
}
