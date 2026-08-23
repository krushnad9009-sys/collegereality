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

  /// The city/state this reply's answer was actually scoped to, when it
  /// came from a general (non-college-anchored) location search -- e.g.
  /// "best colleges in Pune" resolves to city="Pune". Carried forward
  /// in-memory only (not persisted) so a same-session follow-up like "what
  /// about CSE?" can stay scoped to the same place without the user
  /// repeating it. Null whenever the reply had no location of its own
  /// (college-anchored answers, off-topic replies, comparisons, etc).
  final String? resolvedCity;
  final String? resolvedState;

  /// True when this reply's text drew on the LLM's general educational/
  /// career knowledge rather than College Reality's own verified data
  /// (the LLM is instructed to say so inline in the text itself; this is
  /// just a structured mirror of that for callers that want it). Always
  /// false for database-only replies, which by construction never
  /// contain anything but verified data.
  final bool isGeneralAdvice;

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
    this.resolvedCity,
    this.resolvedState,
    this.isGeneralAdvice = false,
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
