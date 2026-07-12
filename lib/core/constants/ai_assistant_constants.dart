class AiAssistantConstants {
  AiAssistantConstants._();

  static const int maxRecommendations = 10;
  static const int maxCompareColleges = 5;
  static const int candidateFetchLimit = 48;
  static const int maxConversationTurns = 30;

  static const List<String> exampleQueries = [
    'Best engineering colleges in Pune',
    'Best MBA colleges under ₹5 lakh',
    'Colleges with hostel in Maharashtra',
    'Colleges with highest placement',
    'Best government colleges',
    'Colleges with NAAC A++',
    'Best colleges for Computer Engineering',
    'Colleges with best campus life',
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
