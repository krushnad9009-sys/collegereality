import 'package:flutter_test/flutter_test.dart';
import 'package:college_reality_india/features/assistant/models/ai_query_intent.dart';
import 'package:college_reality_india/features/assistant/models/ai_college_data_bundle.dart';
import 'package:college_reality_india/features/assistant/models/ai_topic.dart';
import 'package:college_reality_india/features/assistant/services/ai_grounded_answer_builder.dart';
import 'package:college_reality_india/features/assistant/services/ai_topic_detector.dart';
import 'package:college_reality_india/features/assistant/services/ai_query_parser.dart';
import 'package:college_reality_india/features/assistant/services/ai_college_ranker.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';

void main() {
  group('AiQueryParser', () {
    final parser = AiQueryParser();

    test('parses engineering colleges in Pune', () {
      final intent = parser.parse('Best engineering colleges in Pune');
      expect(intent.city, 'Pune');
      expect(intent.course, 'B.Tech');
      expect(intent.type, AiQueryType.search);
    });

    test('parses MBA under 5 lakh', () {
      final intent = parser.parse('Best MBA colleges under ₹5 lakh');
      expect(intent.course, 'MBA');
      expect(intent.maxFees, 500000);
    });

    test('parses Hindi hostel query', () {
      final intent = parser.parse('Hostel wale colleges Maharashtra mein');
      expect(intent.requireHostel, isTrue);
      expect(intent.state, 'Maharashtra');
    });

    test('parses Marathi placement query', () {
      final intent = parser.parse('Sarvochch placement colleges');
      expect(intent.sortBy, AiSortPriority.placements);
    });

    test('parses government and NAAC A++', () {
      final intent = parser.parse('Best government colleges with NAAC A++');
      expect(intent.collegeType, 'government');
      expect(intent.naacGrade, 'A++');
    });

    test('detects comparison with context', () {
      final intent = parser.parse(
        'Which has better placements?',
        contextCollegeIds: ['a', 'b'],
      );
      expect(intent.type, AiQueryType.question);
    });

    test('parses computer engineering course', () {
      final intent = parser.parse('Best colleges for Computer Engineering');
      expect(intent.course, 'Computer Engineering');
    });

    test('parses near me with user city', () {
      final intent = parser.parse(
        'Colleges near me',
        userCity: 'Pune',
      );
      expect(intent.nearMe, isTrue);
      expect(intent.city, 'Pune');
    });
  });

  group('AiCollegeRanker', () {
    final ranker = AiCollegeRanker();

    CollegeModel sample({
      required String id,
      required double overall,
      required int placementPct,
      required int feeMax,
    }) {
      return CollegeModel(
        id: id,
        name: 'College $id',
        nameLower: 'college $id',
        slug: 'college-$id',
        city: 'Pune',
        state: 'Maharashtra',
        address: 'Test',
        type: 'private',
        courses: const ['B.Tech'],
        fees: CollegeFees(tuitionMin: feeMax ~/ 2, tuitionMax: feeMax, hostelAnnual: 0),
        placements: CollegePlacements(
          highestPackageLpa: 20,
          averagePackageLpa: 8,
          placementPercentage: placementPct,
        ),
        aggregatedRatings: CollegeRatings(
          overall: overall,
          faculty: overall,
          infrastructure: overall,
          placements: overall,
          campusLife: overall,
        ),
        reviewCount: 10,
      );
    }

    test('ranks higher placement colleges first', () {
      final low = sample(id: '1', overall: 3, placementPct: 50, feeMax: 200000);
      final high = sample(id: '2', overall: 4, placementPct: 95, feeMax: 300000);
      const intent = AiQueryIntent(
        rawQuery: 'placements',
        sortBy: AiSortPriority.placements,
      );
      final ranked = ranker.rank([low, high], intent);
      expect(ranked.first.college.id, '2');
    });

    test('ranks lower fees first for budget intent', () {
      final cheap = sample(id: '1', overall: 3.5, placementPct: 60, feeMax: 100000);
      final costly = sample(id: '2', overall: 4.5, placementPct: 90, feeMax: 500000);
      const intent = AiQueryIntent(
        rawQuery: 'fees',
        sortBy: AiSortPriority.feesLow,
      );
      final ranked = ranker.rank([costly, cheap], intent);
      expect(ranked.first.college.id, '1');
    });
  });

  group('AiTopicDetector', () {
    final detector = AiTopicDetector();

    test('rejects clearly off-topic queries', () {
      expect(detector.isCollegeRelated('What is the weather today?'), isFalse);
      expect(detector.isCollegeRelated('Write me a python script'), isFalse);
    });

    test('accepts college-related queries', () {
      expect(detector.isCollegeRelated('How are placements at COEP?'), isTrue);
      expect(detector.isCollegeRelated('Hostel review?'), isTrue);
    });

    test('detects CSE and exam score topics', () {
      expect(detector.detectTopic('Is this college good for CSE?'), AiTopic.cse);
      expect(
        detector.detectTopic('Best colleges under my JEE rank 15000'),
        AiTopic.examScore,
      );
    });

    test('extracts JEE and CET scores', () {
      expect(detector.extractExamScore('jee rank 15000')?.examType, 'jee');
      expect(detector.extractExamScore('cet percentile 92')?.score, 92);
    });
  });

  group('AiGroundedAnswerBuilder', () {
    test('builds placement answer from profile data only', () {
      final college = CollegeModel(
        id: 'c1',
        name: 'Test College',
        nameLower: 'test college',
        slug: 'test-college',
        city: 'Pune',
        state: 'Maharashtra',
        address: 'Test',
        type: 'private',
        courses: const ['B.Tech'],
        fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 0),
        placements: const CollegePlacements(
          highestPackageLpa: 18,
          averagePackageLpa: 8,
          placementPercentage: 85,
        ),
        aggregatedRatings: const CollegeRatings(
          overall: 4.2,
          faculty: 4,
          infrastructure: 4,
          placements: 4.5,
          campusLife: 4,
        ),
        reviewCount: 12,
      );

      final bundle = AiCollegeDataBundle(
        college: college,
        fetchedAt: DateTime.now(),
      );
      final answer = AiGroundedAnswerBuilder().build(
        bundle: bundle,
        topic: AiTopic.placements,
        query: 'How are placements?',
      );

      expect(answer.text, contains('85%'));
      expect(answer.text, contains('8.0 LPA'));
      expect(answer.sources, isNotEmpty);
    });
  });
}
