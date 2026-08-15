import 'package:college_reality_india/features/reviews/models/review_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReviewModel fromJson/toJson and copyWith', () {
    final now = DateTime(2026, 1, 1);
    final review = ReviewModel(
      id: 'r1',
      collegeId: 'c1',
      collegeName: 'Test College',
      userId: 'u1',
      anonymousAlias: 'Student #1',
      ratings: const {'overall': 4.5, 'faculty': 4.0},
      createdAt: now,
      updatedAt: now,
      textReview: 'Great campus',
    );
    final json = review.toJson();
    final restored = ReviewModel.fromJson(json, docId: 'r1');
    expect(restored.collegeId, 'c1');
    expect(restored.collegeName, 'Test College');
    expect(restored.overallRating, greaterThan(0));
    expect(restored.copyWith(textReview: 'Updated').textReview, 'Updated');
  });

  test(
      'malformed individual rating fields are dropped, not the whole review '
      '(regression: reviewCount > 0 but Reviews tab empty)', () {
    final json = <String, dynamic>{
      'id': 'r2',
      'collegeId': 'c1',
      'collegeName': 'Test College',
      'userId': 'u2',
      'anonymousAlias': 'Student #2',
      'isAnonymous': true,
      'status': ReviewModel.statusPublished,
      'isVerifiedStudent': true,
      'ratings': {
        'overall': 4.5, // valid
        'faculty': 'not-a-number', // malformed — must not throw
        'infrastructure': null, // malformed — must not throw
        'placements': 3.0, // valid
      },
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    };

    final review = ReviewModel.fromJson(json, docId: 'r2');

    expect(review.ratings['overall'], 4.5);
    expect(review.ratings['placements'], 3.0);
    expect(review.ratings.containsKey('faculty'), isFalse);
    expect(review.ratings.containsKey('infrastructure'), isFalse);
    expect(review.isPublicVisible, isTrue);
  });

  test(
      'a batch with one structurally-broken review does not hide the '
      'valid reviews around it (mirrors FirestoreReviewService._parseReviews)',
      () {
    List<Map<String, dynamic>> rawDocs = [
      {
        'id': 'good1',
        'collegeId': 'c1',
        'status': ReviewModel.statusPublished,
        'isVerifiedStudent': true,
        'ratings': {'overall': 4.0},
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      },
      {
        'id': 'broken',
        'collegeId': 'c1',
        'status': ReviewModel.statusPublished,
        'isVerifiedStudent': true,
        // Wrong type entirely (not a Map) — this is expected to throw
        // during parsing, exercising the per-document catch-and-skip path.
        'ratings': 'this-should-be-a-map',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      },
      {
        'id': 'good2',
        'collegeId': 'c1',
        'status': ReviewModel.statusPublished,
        'isVerifiedStudent': true,
        'ratings': {'overall': 5.0},
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      },
    ];

    final parsed = <ReviewModel>[];
    for (final doc in rawDocs) {
      try {
        parsed.add(ReviewModel.fromJson(doc, docId: doc['id'] as String));
      } catch (_) {
        // Same skip-malformed-document behavior as the production service.
      }
    }

    expect(parsed.map((r) => r.id), containsAll(['good1', 'good2']));
    expect(parsed.any((r) => r.id == 'broken'), isFalse);
    expect(parsed.length, 2);
  });
}