import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/question_constants.dart';
import 'package:college_reality_india/features/questions/models/answer_model.dart';
import 'package:college_reality_india/features/questions/models/question_model.dart';
import 'package:college_reality_india/features/questions/utils/question_display_utils.dart';
import 'package:college_reality_india/features/questions/utils/question_mention_utils.dart';
import 'package:college_reality_india/features/questions/utils/question_rich_text_utils.dart';

void main() {
  group('QuestionDisplayUtils', () {
    QuestionModel sampleQuestion({
      required String id,
      required String title,
      int answerCount = 0,
      String? mostHelpfulAnswerId,
      int mostHelpfulScore = 0,
      int topAnswerScore = 0,
      String category = QuestionConstants.categoryHostel,
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
        category: category,
        searchText: buildQuestionSearchText(title, 'Details about $title', category: category),
        answerCount: answerCount,
        mostHelpfulAnswerId: mostHelpfulAnswerId,
        mostHelpfulScore: mostHelpfulScore,
        topAnswerScore: topAnswerScore,
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

    test('filterAndSortQuestions supports category filter', () {
      final questions = [
        sampleQuestion(id: '1', title: 'Hostel food quality', category: QuestionConstants.categoryHostel),
        sampleQuestion(id: '2', title: 'Placement support', category: QuestionConstants.categoryPlacement),
      ];

      final hostelOnly = filterAndSortQuestions(
        questions: questions,
        filter: QuestionConstants.filterLatest,
        searchQuery: '',
        category: QuestionConstants.categoryHostel,
      );
      expect(hostelOnly.length, 1);
      expect(hostelOnly.first.id, '1');
    });

    test('filterAndSortQuestions supports most upvoted sort', () {
      final questions = [
        sampleQuestion(id: '1', title: 'Low votes', topAnswerScore: 2),
        sampleQuestion(id: '2', title: 'High votes', topAnswerScore: 20),
      ];

      final sorted = filterAndSortQuestions(
        questions: questions,
        filter: QuestionConstants.filterMostUpvoted,
        searchQuery: '',
      );
      expect(sorted.first.id, '2');
    });

    test('filterAndSortQuestions supports search and unanswered filter', () {
      final questions = [
        sampleQuestion(id: '1', title: 'Hostel food quality'),
        sampleQuestion(id: '2', title: 'Placement support', answerCount: 2),
      ];

      final unanswered = filterAndSortQuestions(
        questions: questions,
        filter: QuestionConstants.filterUnanswered,
        searchQuery: '',
      );
      expect(unanswered.length, 1);
      expect(unanswered.first.id, '1');
    });

    test('filterBlockedAuthors removes blocked users', () {
      final questions = [
        sampleQuestion(id: '1', title: 'A'),
        sampleQuestion(id: '2', title: 'B'),
      ];
      final filtered = filterBlockedAuthors(questions, {'u1'});
      expect(filtered, isEmpty);
    });

    test('sortAnswers prioritizes accepted then most helpful', () {
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
          body: 'Accepted',
          score: 2,
          isAccepted: true,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      final sorted = sortAnswers(answers);
      expect(sorted.first.id, 'a2');
    });

    test('paginateQuestions limits visible count', () {
      final questions = List.generate(
        30,
        (i) => sampleQuestion(id: '$i', title: 'Q$i'),
      );
      final page = paginateQuestions(questions, page: 0, pageSize: 20);
      expect(page.length, 20);
      expect(hasMoreQuestions(questions, 20), isTrue);
    });
  });

  group('QuestionMentionUtils', () {
    test('extracts mention user ids from rich text', () {
      final ids = QuestionMentionUtils.extractMentionUserIds(
        'Thanks @[Rahul](user123) for the help',
      );
      expect(ids, ['user123']);
    });
  });

  group('QuestionRichTextUtils', () {
    test('wrapBold adds markdown markers', () {
      expect(QuestionRichTextUtils.wrapBold('test'), '**test**');
    });
  });
}
