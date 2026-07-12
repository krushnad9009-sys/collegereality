import 'ai_college_recommendation.dart';
import 'ai_comparison_result.dart';
import 'ai_suggestion_group.dart';

enum AiMessageRole { user, assistant }

class AiAssistantMessage {
  final String id;
  final AiMessageRole role;
  final String text;
  final List<AiCollegeRecommendation> recommendations;
  final AiComparisonResult? comparison;
  final List<AiSuggestionGroup> suggestions;
  final DateTime createdAt;
  final bool dataGrounded;

  const AiAssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    this.recommendations = const [],
    this.comparison,
    this.suggestions = const [],
    required this.createdAt,
    this.dataGrounded = true,
  });
}
