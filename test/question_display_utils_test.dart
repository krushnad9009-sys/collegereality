import 'package:college_reality_india/core/constants/question_constants.dart';
import 'package:college_reality_india/features/questions/models/answer_model.dart';
import 'package:college_reality_india/features/questions/models/question_model.dart';
import 'package:college_reality_india/features/questions/utils/question_display_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  QuestionModel q({
    required String id,
    String title = 'Title',
    String body = 'Body',
    String category = QuestionConstants.categoryAdmission,
    String authorId = 'u1',
    int answerCount = 0,
    String? mostHelpfulAnswerId,
    int mostHelpfulScore = 0,
    int topAnswerScore = 0,
    DateTime? createdAt,
  }) {
    return QuestionModel(
      id: id,
      collegeId: 'c1',
      collegeName: 'COEP',
      authorId: authorId,
      authorDisplayName: 'Ada',
      title: title,
      body: body,
      category: category,
      searchText: '$title $body'.toLowerCase(),
      answerCount: answerCount,
      mostHelpfulAnswerId: mostHelpfulAnswerId,
      mostHelpfulScore: mostHelpfulScore,
      topAnswerScore: topAnswerScore,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  test('search text and author helpers', () {
    expect(buildQuestionSearchText('Hello', 'World', category: 'x'), contains('hello'));
    expect(normalizeQuestionContent('Hi!!! World'), 'hi world');
    expect(buildAnonymousQuestionAlias('uid'), isNotEmpty);
    expect(
      resolveAuthorDisplayName(userId: 'u1', displayName: 'Ada', isAnonymous: false),
      'Ada',
    );
    expect(
      resolveAuthorDisplayName(userId: 'u1', displayName: null, isAnonymous: true),
      isNotEmpty,
    );
    expect(
      resolveAuthorDisplayName(userId: 'u1', displayName: '  ', isAnonymous: false),
      contains('Student'),
    );
  });

  test('filter/sort/paginate questions and answers', () {
    final questions = [
      q(id: '1', title: 'Placements?', answerCount: 0, createdAt: now),
      q(
        id: '2',
        title: 'Hostel?',
        category: QuestionConstants.categoryHostel,
        answerCount: 2,
        mostHelpfulAnswerId: 'a1',
        mostHelpfulScore: 5,
        topAnswerScore: 5,
        createdAt: now.add(const Duration(days: 1)),
      ),
      q(id: '3', title: 'Fees?', authorId: 'blocked', createdAt: now.add(const Duration(days: 2))),
    ];

    expect(matchesQuestionSearch(questions.first, 'place'), isTrue);
    expect(filterBlockedAuthors(questions, {'blocked'}).length, 2);

    final unanswered = filterAndSortQuestions(
      questions: questions,
      filter: QuestionConstants.filterUnanswered,
      searchQuery: '',
    );
    expect(unanswered.every((x) => x.isUnanswered), isTrue);

    final helpful = filterAndSortQuestions(
      questions: questions,
      filter: QuestionConstants.filterMostHelpful,
      searchQuery: '',
    );
    expect(helpful.first.id, '2');

    final upvoted = filterAndSortQuestions(
      questions: questions,
      filter: QuestionConstants.filterMostUpvoted,
      searchQuery: 'hostel',
      category: QuestionConstants.categoryHostel,
    );
    expect(upvoted.length, 1);

    final page = paginateQuestions(questions, page: 0, pageSize: 2);
    expect(page.length, 2);
    expect(hasMoreQuestions(questions, 2), isTrue);

    final answers = [
      AnswerModel(
        id: 'a1',
        questionId: '1',
        collegeId: 'c1',
        authorId: 'u1',
        authorDisplayName: 'Ada',
        body: 'Yes',
        score: 1,
        createdAt: now,
        updatedAt: now,
      ),
      AnswerModel(
        id: 'a2',
        questionId: '1',
        collegeId: 'c1',
        authorId: 'blocked',
        authorDisplayName: 'X',
        body: 'No',
        score: 10,
        isAccepted: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    expect(filterBlockedAnswerAuthors(answers, {'blocked'}).length, 1);
    final sorted = sortAnswers(answers);
    expect(sorted.first.isAccepted, isTrue);
  });
}