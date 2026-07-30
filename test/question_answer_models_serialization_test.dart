import 'package:college_reality_india/core/constants/question_constants.dart';
import 'package:college_reality_india/features/questions/models/answer_model.dart';
import 'package:college_reality_india/features/questions/models/question_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 2, 5, 9, 0);

  group('QuestionModel JSON', () {
    test('round-trip preserves engagement and mentions', () {
      final original = QuestionModel(
        id: 'q-1',
        collegeId: 'col-1',
        collegeName: 'COEP',
        authorId: 'user-1',
        authorDisplayName: 'Rahul',
        isAnonymous: false,
        isAuthorVerified: true,
        title: 'Hostel WiFi speed?',
        body: 'Is WiFi usable for coding?',
        searchText: 'hostel wifi coep',
        category: QuestionConstants.categoryHostel,
        imageUrls: const ['https://example.com/img.jpg'],
        mentionUserIds: const ['user-2'],
        answerCount: 3,
        mostHelpfulScore: 12,
        topAnswerScore: 8,
        mostHelpfulAnswerId: 'ans-1',
        acceptedAnswerId: 'ans-2',
        status: QuestionConstants.statusPublished,
        createdAt: now,
        updatedAt: now,
      );
      final restored = QuestionModel.fromJson(original.toJson(), docId: 'q-1');
      expect(restored.title, original.title);
      expect(restored.mentionUserIds, ['user-2']);
      expect(restored.mostHelpfulAnswerId, 'ans-1');
      expect(restored.acceptedAnswerId, 'ans-2');
    });

    test('getters reflect question state', () {
      final unanswered = QuestionModel(
        id: 'q', collegeId: 'c', collegeName: 'C', authorId: 'a',
        authorDisplayName: 'S', title: 'T', answerCount: 0,
        createdAt: now, updatedAt: now,
      );
      expect(unanswered.isUnanswered, isTrue);
      expect(unanswered.hasAcceptedAnswer, isFalse);
      expect(unanswered.isPublicVisible, isTrue);
    });

    test('normalizeStatus lowercases and defaults', () {
      expect(QuestionModel.normalizeStatus(null), QuestionConstants.statusPublished);
      expect(QuestionModel.normalizeStatus('  PUBLISHED  '), 'published');
    });

    test('copyWith updates selected fields', () {
      final q = QuestionModel(
        id: 'q', collegeId: 'c', collegeName: 'C', authorId: 'a',
        authorDisplayName: 'S', title: 'Old', createdAt: now, updatedAt: now,
      );
      final updated = q.copyWith(title: 'New', answerCount: 5);
      expect(updated.title, 'New');
      expect(updated.answerCount, 5);
      expect(updated.id, 'q');
    });
  });

  group('AnswerModel JSON', () {
    test('round-trip preserves votes and badges', () {
      final original = AnswerModel(
        id: 'ans-1',
        questionId: 'q-1',
        collegeId: 'col-1',
        authorId: 'user-2',
        authorDisplayName: 'Priya',
        isVerifiedStudent: true,
        reviewerBadge: 'verified_student',
        body: 'WiFi is decent in Block A.',
        imageUrls: const ['https://example.com/a.jpg'],
        mentionUserIds: const ['user-1'],
        upvoteCount: 10,
        downvoteCount: 1,
        score: 9,
        replyCount: 2,
        isMostHelpful: true,
        isAccepted: true,
        status: QuestionConstants.statusPublished,
        createdAt: now,
        updatedAt: now,
      );
      final restored = AnswerModel.fromJson(original.toJson(), docId: 'ans-1');
      expect(restored.score, 9);
      expect(restored.isMostHelpful, isTrue);
      expect(restored.reviewerBadge, 'verified_student');
      expect(restored.isPublicVisible, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final answer = AnswerModel(
        id: 'a', questionId: 'q', collegeId: 'c', authorId: 'u',
        authorDisplayName: 'S', body: 'Body', createdAt: now, updatedAt: now,
      );
      final updated = answer.copyWith(score: 5, isAccepted: true);
      expect(updated.score, 5);
      expect(updated.isAccepted, isTrue);
      expect(updated.body, 'Body');
    });
  });
}
