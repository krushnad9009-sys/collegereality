import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/question_constants.dart';
import 'package:college_reality_india/features/questions/models/answer_model.dart';
import 'package:college_reality_india/features/questions/models/question_model.dart';
import 'package:college_reality_india/features/questions/utils/question_display_utils.dart';

void main() {
  group('QuestionDisplayUtils', () {
    QuestionModel sampleQuestion({
      required String id,
      required String title,
      int answerCount = 0,
      String? mostHelpfulAnswerId,
      int mostHelpfulScore = 0,
      DateTime? createdAt,
    }) {
      final now = createdAt ?? DateTime(2024, 6, 1);
      return QuestionModel(
        id: id,
        collegeId: 'c1',
        collegeName: 'Test College',
        authorId: 'u1',
        authorDisplayName: 'Student',
        title: title,
        body: 'Details about $title',
        searchText: buildQuestionSearchText(title, 'Details about $title'),
        answerCount: answerCount,
        mostHelpfulAnswerId: mostHelpfulAnswerId,
        mostHelpfulScore: mostHelpfulScore,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('buildAnonymousQuestionAlias hides user identity', () {
      final alias = buildAnonymousQuestionAlias('user-abc');
      expect(alias.startsWith('Anonymous Verified Student #'), isTrue);
    });

    test('resolveAuthorDisplayName uses real name when not anonymous', () {
      expect(
        resolveAuthorDisplayName(
          userId: 'u1',
          displayName: 'Rahul Sharma',
          isAnonymous: false,
        ),
        'Rahul Sharma',
      );
    });

    test('filterAndSortQuestions supports search and unanswered filter', () {
      final questions = [
        sampleQuestion(id: '1', title: 'Hostel food quality'),
        sampleQuestion(id: '2', title: 'Placement support', answerCount: 2),
        sampleQuestion(
          id: '3',
          title: 'Campus wifi',
          answerCount: 1,
          mostHelpfulAnswerId: 'a1',
          mostHelpfulScore: 5,
          createdAt: DateTime(2024, 7, 1),
        ),
      ];

      final unanswered = filterAndSortQuestions(
        questions: questions,
        filter: QuestionConstants.filterUnanswered,
        searchQuery: '',
      );
      expect(unanswered.length, 1);
      expect(unanswered.first.id, '1');

      final searched = filterAndSortQuestions(
        questions: questions,
        filter: QuestionConstants.filterLatest,
        searchQuery: 'placement',
      );
      expect(searched.length, 1);
      expect(searched.first.title, contains('Placement'));
    });

    test('sortAnswers prioritizes most helpful and score', () {
      final answers = [
        AnswerModel(
          id: 'a1',
          questionId: 'q1',
          collegeId: 'c1',
          authorId: 'u1',
          authorDisplayName: 'A',
          body: 'Low score',
          score: 1,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        AnswerModel(
          id: 'a2',
          questionId: 'q1',
          collegeId: 'c1',
          authorId: 'u2',
          authorDisplayName: 'B',
          body: 'Most helpful',
          score: 2,
          isMostHelpful: true,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
        AnswerModel(
          id: 'a3',
          questionId: 'q1',
          collegeId: 'c1',
          authorId: 'u3',
          authorDisplayName: 'C',
          body: 'High score',
          score: 10,
          createdAt: DateTime(2024, 1, 3),
          updatedAt: DateTime(2024, 1, 3),
        ),
      ];

      final sorted = sortAnswers(answers);
      expect(sorted.first.id, 'a2');
      expect(sorted[1].id, 'a3');
    });
  });
}
