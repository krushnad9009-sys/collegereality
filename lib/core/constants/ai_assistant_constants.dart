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
    'Is ragging reported?',
    'Compare two colleges',
    'Best colleges under my CET percentile 92',
    'Best engineering colleges in Pune under ₹5 lakh',
  ];

  /// "Try asking" prompts shown when the assistant is opened from a
  /// College Detail page (`anchorCollegeId` set). This is a fixed,
  /// hand-written list -- NOT generated from the college's data, NOT
  /// derived from any AI response, and NOT computed per-college (no
  /// college-name templating, no CTC/package/placement-number questions).
  /// Tapping one still runs the real Firestore-grounded pipeline scoped to
  /// whichever college is currently anchored, same as typing it manually;
  /// only the displayed prompt TEXT is a static constant.
  static const List<String> collegeExampleQueries = [
    'Is this college good?',
    'How are the placements?',
    'How is student life?',
    'How is the campus?',
    'What do students say about this college?',
    'How is the hostel?',
    'Is this college good for CSE?',
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
