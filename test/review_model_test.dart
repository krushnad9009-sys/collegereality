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
}