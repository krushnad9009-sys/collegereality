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

  static const List<String> exampleQueries = [
    'Is this college good for CSE?',
    'How are placements?',
    'Hostel review?',
    'Average package?',
    'Is ragging reported?',
    'Compare two colleges',
    'Best colleges under my CET percentile 92',
    'Best engineering colleges in Pune under ₹5 lakh',
  ];

  /// "Try asking" prompts scoped to a specific college — used when the
  /// assistant is opened from a College Detail page (`anchorCollegeName`
  /// set). Every question routes through the same real, Firestore-grounded
  /// query pipeline as [exampleQueries]; only the displayed prompt text is
  /// templated with the real college name.
  static List<String> collegeExampleQueries(String collegeName) => [
        'Is $collegeName good for CSE?',
        'How are placements at $collegeName?',
        'What is the hostel experience at $collegeName?',
        'What do verified students say about $collegeName?',
        'What is the average package at $collegeName?',
      ];

  static const List<String> exampleQueriesHi = [
    'Pune mein best engineering colleges',
    '₹5 lakh ke andar MBA colleges',
    'Hostel wale colleges',
  ];

  static const List<String> exampleQueriesMr = [
    'Pune madhe best engineering colleges',
    'Hostel aslele colleges',
    'Sarvochch placement colleges',
  ];
}
