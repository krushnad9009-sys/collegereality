import 'package:college_reality_india/features/assistant/models/ai_college_data_bundle.dart';
import 'package:college_reality_india/features/assistant/models/ai_topic.dart';
import 'package:college_reality_india/features/assistant/services/ai_grounded_answer_builder.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/reviews/models/review_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CollegeModel college() {
    return CollegeModel(
      id: 'c1',
      name: 'Test College',
      nameLower: 'test college',
      slug: 'test-college',
      city: 'Pune',
      state: 'Maharashtra',
      address: 'Test',
      type: 'private',
      courses: const ['Computer Engineering', 'B.Tech'],
      fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 60000),
      hostel: const CollegeHostel(available: true, messIncluded: true, annualFee: 60000),
      placements: const CollegePlacements(
        highestPackageLpa: 18,
        averagePackageLpa: 8,
        placementPercentage: 85,
      ),
      aggregatedRatings: const CollegeRatings(
        overall: 4.2,
        faculty: 4.1,
        infrastructure: 4,
        placements: 4.5,
        campusLife: 4,
        hostel: 3.8,
        food: 3.5,
      ),
      reviewCount: 12,
    );
  }

  ReviewModel review() {
    return ReviewModel(
      id: 'r1',
      collegeId: 'c1',
      collegeName: 'Test College',
      userId: 'u1',
      anonymousAlias: 'Student #1',
      ratings: const {'overall': 4.0, 'faculty': 4.5, 'hostel': 4.0, 'campusLife': 4.0, 'placements': 4.0},
      textReview: 'Good faculty and hostel. No ragging. Campus life is vibrant.',
      yesNoAnswers: const {'raggingPresent': false},
      isVerifiedStudent: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('builds answers for all major topics', () {
    final bundle = AiCollegeDataBundle(
      college: college(),
      reviews: [review()],
      fetchedAt: DateTime.now(),
    );
    final builder = AiGroundedAnswerBuilder();
    for (final topic in AiTopic.values) {
      final answer = builder.build(
        bundle: bundle,
        topic: topic,
        query: 'Tell me about ${topic.name}',
      );
      expect(answer.text, isNotEmpty, reason: topic.name);
      expect(answer.sources, isNotEmpty, reason: topic.name);
      expect(answer.text, contains('College Reality'));
    }
  });

  test('handles sparse college data without crashing', () {
    final sparse = CollegeModel.createDraft(id: 'x');
    final answer = AiGroundedAnswerBuilder().build(
      bundle: AiCollegeDataBundle(college: sparse, fetchedAt: DateTime.now()),
      topic: AiTopic.general,
      query: 'anything',
    );
    expect(answer.text, isNotEmpty);
  });
}