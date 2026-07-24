import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/features/compare/utils/compare_pros_cons_utils.dart';
import 'package:college_reality_india/features/reviews/models/review_model.dart';

void main() {
  test('CompareProsConsUtils aggregates frequent pros and cons', () {
    final reviews = [
      ReviewModel(
        id: '1',
        collegeId: 'c1',
        collegeName: 'Test',
        userId: 'u1',
        anonymousAlias: 'Student #1',
        ratings: const {'overall': 4},
        pros: const ['Good placements', 'Strong faculty'],
        cons: const ['High fees'],
        isVerifiedStudent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ReviewModel(
        id: '2',
        collegeId: 'c1',
        collegeName: 'Test',
        userId: 'u2',
        anonymousAlias: 'Student #2',
        ratings: const {'overall': 5},
        pros: const ['Good placements', 'Nice campus'],
        cons: const ['High fees', 'Strict attendance'],
        isVerifiedStudent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final result = CompareProsConsUtils.buildForCollege(
      collegeId: 'c1',
      collegeName: 'Test College',
      reviews: reviews,
    );

    expect(result.pros.first.toLowerCase(), contains('good placements'));
    expect(result.cons.first.toLowerCase(), contains('high fees'));
  });
}
