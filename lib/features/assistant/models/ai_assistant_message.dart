import 'ai_college_recommendation.dart';
import 'ai_topic.dart';
import 'ai_source_citation.dart';
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
  final List<AiSourceCitation> sources;
  final AiAssistantMode mode;
  final DateTime createdAt;
  final bool dataGrounded;

  const AiAssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    this.recommendations = const [],
    this.comparison,
    this.suggestions = const [],
    this.sources = const [],
    this.mode = AiAssistantMode.chat,
    required this.createdAt,
    this.dataGrounded = true,
  });

  factory AiAssistantMessage.fromJson(Map<String, dynamic> json) {
    return AiAssistantMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] == 'user' ? AiMessageRole.user : AiMessageRole.assistant,
      text: json['text'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => AiSourceCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mode: json['mode'] == 'compare'
          ? AiAssistantMode.compare
          : AiAssistantMode.chat,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      dataGrounded: json['dataGrounded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role == AiMessageRole.user ? 'user' : 'assistant',
        'text': text,
        'sources': sources.map((s) => s.toJson()).toList(),
        'mode': mode == AiAssistantMode.compare ? 'compare' : 'chat',
        'createdAt': createdAt.toIso8601String(),
        'dataGrounded': dataGrounded,
      };
}
