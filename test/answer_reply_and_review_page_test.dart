import 'package:college_reality_india/core/constants/question_constants.dart';
import 'package:college_reality_india/features/questions/models/answer_reply_model.dart';
import 'package:college_reality_india/features/reviews/models/review_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('AnswerReplyModel JSON and status helpers', () {
    expect(AnswerReplyModel.normalizeStatus(null), QuestionConstants.statusPublished);
    expect(AnswerReplyModel.normalizeStatus('  HIDDEN '), 'hidden');
    final reply = AnswerReplyModel(
      id: 'r1',
      questionId: 'q1',
      answerId: 'a1',
      authorId: 'u1',
      authorDisplayName: 'Ada',
      body: 'Nice',
      imageUrls: const ['https://x'],
      mentionUserIds: const ['u2'],
      createdAt: now,
      updatedAt: now,
    );
    expect(reply.isPublicVisible, isTrue);
    final restored = AnswerReplyModel.fromJson(reply.toJson(), docId: 'r1');
    expect(restored.body, 'Nice');
    expect(restored.imageUrls, ['https://x']);
    expect(AnswerReplyModel.fromJson({}).authorDisplayName, 'Student');
  });

  test('RatingDistribution and ReviewAggregationMeta', () {
    expect(RatingDistribution.fromJson(null).total, 0);
    final dist = RatingDistribution(buckets: {1: 1, 2: 0, 3: 2, 4: 3, 5: 4});
    expect(dist.total, 10);
    expect(dist.countFor(5), 4);
    expect(dist.fractionFor(5), 0.4);
    expect(dist.fractionFor(1), 0.1);
    expect(RatingDistribution().fractionFor(5), 0);
    final applied = dist.applyStar(5, delta: 1);
    expect(applied.countFor(5), 5);
    expect(RatingDistribution.starBucketFor(0), 3);
    expect(RatingDistribution.starBucketFor(4.6), 5);
    final round = RatingDistribution.fromJson(dist.toJson());
    expect(round.countFor(4), 3);

    expect(ReviewAggregationMeta.fromJson(null).reviewCount, 0);
    final meta = ReviewAggregationMeta(
      dimensionSums: const {'faculty': 12},
      dimensionCounts: const {'faculty': 3},
      starDistribution: const {'5': 2},
      yesNoYesCounts: const {'hostel': 1},
      yesNoTotalCounts: const {'hostel': 2},
      reviewCount: 3,
    );
    final restored = ReviewAggregationMeta.fromJson(meta.toJson());
    expect(restored.reviewCount, 3);
    expect(restored.dimensionSums['faculty'], 12);

    const page = ReviewPage(reviews: [], lastDocumentId: 'x', hasMore: true);
    expect(page.hasMore, isTrue);
  });
}