import 'ai_college_recommendation.dart';

enum AiSuggestionType {
  similar,
  betterAlternative,
  budgetAlternative,
  nearbyAlternative,
}

class AiSuggestionGroup {
  final AiSuggestionType type;
  final String title;
  final List<AiCollegeRecommendation> items;

  const AiSuggestionGroup({
    required this.type,
    required this.title,
    required this.items,
  });
}
