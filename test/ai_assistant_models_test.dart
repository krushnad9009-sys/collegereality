import 'package:college_reality_india/features/assistant/models/ai_assistant_message.dart';
import 'package:college_reality_india/features/assistant/models/ai_college_recommendation.dart';
import 'package:college_reality_india/features/assistant/models/ai_comparison_result.dart';
import 'package:college_reality_india/features/assistant/models/ai_query_intent.dart';
import 'package:college_reality_india/features/assistant/models/ai_source_citation.dart';
import 'package:college_reality_india/features/assistant/models/ai_suggestion_group.dart';
import 'package:college_reality_india/features/assistant/models/ai_topic.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('AiSourceCitation JSON round-trip and unknown type default', () {
    const citation = AiSourceCitation(
      type: AiSourceType.review,
      id: 'r1',
      label: 'Review',
      excerpt: 'Great hostel',
      actionRoute: '/c/1',
    );
    final restored = AiSourceCitation.fromJson(citation.toJson());
    expect(restored.type, AiSourceType.review);
    expect(restored.excerpt, 'Great hostel');
    expect(AiSourceCitation.fromJson({'type': 'missing'}).type, AiSourceType.profile);
  });

  test('AiAssistantMessage JSON round-trip for user and compare modes', () {
    final user = AiAssistantMessage(
      id: 'm1',
      role: AiMessageRole.user,
      text: 'Best CSE?',
      createdAt: now,
    );
    final userRestored = AiAssistantMessage.fromJson(user.toJson());
    expect(userRestored.role, AiMessageRole.user);
    expect(userRestored.mode, AiAssistantMode.chat);

    final assistant = AiAssistantMessage(
      id: 'm2',
      role: AiMessageRole.assistant,
      text: 'Here are options',
      sources: const [
        AiSourceCitation(
          type: AiSourceType.profile,
          id: 'c1',
          label: 'Profile',
          excerpt: 'CSE',
        ),
      ],
      mode: AiAssistantMode.compare,
      createdAt: now,
      dataGrounded: false,
    );
    final restored = AiAssistantMessage.fromJson(assistant.toJson());
    expect(restored.mode, AiAssistantMode.compare);
    expect(restored.sources, hasLength(1));
    expect(restored.dataGrounded, isFalse);
    expect(AiAssistantMessage.fromJson({}).id, '');
  });

  test('AiQueryIntent and recommendation/suggestion/comparison containers', () {
    const intent = AiQueryIntent(rawQuery: 'near me', nearMe: true, city: 'Pune');
    expect(intent.hasLocationFilter, isTrue);
    expect(const AiQueryIntent(rawQuery: 'x').hasLocationFilter, isFalse);

    final college = CollegeModel.createDraft(id: 'c1');
    final rec = AiCollegeRecommendation(
      college: college,
      score: 90,
      reasons: const ['Strong reviews'],
      rank: 1,
    );
    expect(rec.score, 90);
    expect(rec.rank, 1);

    const group = AiSuggestionGroup(
      type: AiSuggestionType.budgetAlternative,
      title: 'Budget picks',
      items: [],
    );
    expect(group.type, AiSuggestionType.budgetAlternative);

    const compare = AiComparisonResult(
      colleges: [],
      rows: [
        AiComparisonRow(metric: 'Fees', values: ['1L', '2L'], winnerIndex: 0),
      ],
      summary: 'A wins on fees',
      overallWinnerIndex: 0,
    );
    expect(compare.rows.first.winnerIndex, 0);
    expect(AiTopic.values, contains(AiTopic.placements));
  });
}