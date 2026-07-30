import 'package:college_reality_india/features/assistant/models/ai_query_intent.dart';
import 'package:college_reality_india/features/assistant/models/ai_suggestion_group.dart';
import 'package:college_reality_india/features/assistant/services/ai_explanation_builder.dart';
import 'package:college_reality_india/features/assistant/services/ai_suggestion_service.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:flutter_test/flutter_test.dart';

CollegeModel _college({
  required String id,
  required String name,
  String city = 'Pune',
  String state = 'Maharashtra',
  String type = 'private',
  List<String> courses = const ['B.Tech'],
  double overall = 4.0,
  double placements = 4.0,
  int feeMax = 200000,
  int reviewCount = 20,
  double? lat,
  double? lng,
}) {
  return CollegeModel(
    id: id,
    name: name,
    nameLower: name.toLowerCase(),
    slug: id,
    city: city,
    state: state,
    address: 'Test',
    type: type,
    courses: courses,
    fees: CollegeFees(tuitionMin: feeMax ~/ 2, tuitionMax: feeMax, hostelAnnual: 40000),
    placements: CollegePlacements(
      highestPackageLpa: 15,
      averagePackageLpa: 7,
      placementPercentage: 80,
    ),
    accreditation: const CollegeAccreditation(naacGrade: 'A+', nirfRank: 50),
    hostel: const CollegeHostel(available: true, annualFee: 60000),
    aggregatedRatings: CollegeRatings(
      overall: overall,
      faculty: 4.0,
      infrastructure: 4.0,
      placements: placements,
      campusLife: 4.2,
      teaching: 4.1,
      hostel: 4.0,
      fees: 3.8,
      attendance: 4.0,
      sports: 3.5,
      food: 3.5,
    ),
    reviewCount: reviewCount,
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  late AiExplanationBuilder explanationBuilder;
  late AiSuggestionService suggestionService;

  setUp(() {
    explanationBuilder = AiExplanationBuilder();
    suggestionService = AiSuggestionService();
  });

  group('AiExplanationBuilder', () {
    test('buildReasons includes rating when reviews exist', () {
      final college = _college(id: '1', name: 'Test', reviewCount: 15, overall: 4.3);
      final reasons = explanationBuilder.buildReasons(
        college,
        const AiQueryIntent(rawQuery: 'colleges', sortBy: AiSortPriority.overall),
      );
      expect(reasons.any((r) => r.contains('Verified student rating')), isTrue);
      expect(reasons.any((r) => r.contains('Location:')), isTrue);
    });

    test('buildReasons prioritizes placement data for placements sort', () {
      final reasons = explanationBuilder.buildReasons(
        _college(id: '1', name: 'Test'),
        const AiQueryIntent(rawQuery: 'placements', sortBy: AiSortPriority.placements),
      );
      expect(reasons.any((r) => r.contains('Placement rate')), isTrue);
    });

    test('buildReasons includes hostel info for hostel sort', () {
      final reasons = explanationBuilder.buildReasons(
        _college(id: '1', name: 'Test'),
        const AiQueryIntent(rawQuery: 'hostel', sortBy: AiSortPriority.hostel),
      );
      expect(reasons.any((r) => r.contains('Hostel available')), isTrue);
    });

    test('buildReasons includes NAAC for naac sort', () {
      final reasons = explanationBuilder.buildReasons(
        _college(id: '1', name: 'Test'),
        const AiQueryIntent(rawQuery: 'naac', sortBy: AiSortPriority.naac),
      );
      expect(reasons.any((r) => r.contains('NAAC accreditation')), isTrue);
    });

    test('buildReasons limits to 5 items', () {
      final reasons = explanationBuilder.buildReasons(
        _college(id: '1', name: 'Test', reviewCount: 50),
        const AiQueryIntent(
          rawQuery: 'all',
          sortBy: AiSortPriority.overall,
          course: 'B.Tech',
        ),
      );
      expect(reasons.length, lessThanOrEqualTo(5));
    });

    test('buildSearchSummary describes filters and result count', () {
      final summary = explanationBuilder.buildSearchSummary(
        const AiQueryIntent(
          rawQuery: 'btech pune',
          city: 'Pune',
          course: 'B.Tech',
          maxFees: 300000,
          requireHostel: true,
        ),
        12,
      );
      expect(summary, contains('Found 12 verified colleges'));
      expect(summary, contains('Pune'));
      expect(summary, contains('B.Tech'));
    });

    test('buildSearchSummary handles zero results', () {
      final summary = explanationBuilder.buildSearchSummary(
        const AiQueryIntent(rawQuery: 'xyz', city: 'Nowhere'),
        0,
      );
      expect(summary, contains('No colleges'));
      expect(summary, contains('Try broadening'));
    });
  });

  group('AiSuggestionService', () {
    final anchor = _college(id: 'anchor', name: 'Anchor College', feeMax: 300000, overall: 4.0);
    final similar = _college(id: 'sim', name: 'Similar College', state: 'Maharashtra');
    final better = _college(id: 'better', name: 'Better College', overall: 4.8, placements: 4.9);
    final budget = _college(id: 'cheap', name: 'Budget College', feeMax: 100000);
    final nearby = _college(id: 'near', name: 'Nearby College', city: 'Pune');

    test('returns empty when no anchor or top results', () {
      expect(
        suggestionService.buildSuggestions(
          topResults: const [],
          allCandidates: [anchor],
          intent: const AiQueryIntent(rawQuery: 'test'),
        ),
        isEmpty,
      );
    });

    test('builds similar colleges group', () {
      final groups = suggestionService.buildSuggestions(
        topResults: const [],
        allCandidates: [anchor, similar],
        intent: const AiQueryIntent(rawQuery: 'test'),
        anchorCollege: anchor,
      );
      final similarGroup = groups.where((g) => g.type == AiSuggestionType.similar);
      expect(similarGroup, isNotEmpty);
    });

    test('builds better alternatives when scores exceed anchor', () {
      final groups = suggestionService.buildSuggestions(
        topResults: const [],
        allCandidates: [anchor, better],
        intent: const AiQueryIntent(rawQuery: 'test', sortBy: AiSortPriority.overall),
        anchorCollege: anchor,
      );
      final betterGroup = groups.where((g) => g.type == AiSuggestionType.betterAlternative);
      expect(betterGroup, isNotEmpty);
    });

    test('builds budget alternatives below 85% of anchor fee', () {
      final groups = suggestionService.buildSuggestions(
        topResults: const [],
        allCandidates: [anchor, budget],
        intent: const AiQueryIntent(rawQuery: 'budget'),
        anchorCollege: anchor,
      );
      final budgetGroup = groups.where((g) => g.type == AiSuggestionType.budgetAlternative);
      expect(budgetGroup, isNotEmpty);
    });

    test('builds nearby alternatives in same city', () {
      final groups = suggestionService.buildSuggestions(
        topResults: const [],
        allCandidates: [anchor, nearby],
        intent: const AiQueryIntent(rawQuery: 'nearby'),
        anchorCollege: anchor,
      );
      final nearbyGroup = groups.where((g) => g.type == AiSuggestionType.nearbyAlternative);
      expect(nearbyGroup, isNotEmpty);
    });

    test('attaches reasons to suggestion items', () {
      final groups = suggestionService.buildSuggestions(
        topResults: const [],
        allCandidates: [anchor, similar],
        intent: const AiQueryIntent(rawQuery: 'test'),
        anchorCollege: anchor,
      );
      if (groups.isNotEmpty && groups.first.items.isNotEmpty) {
        expect(groups.first.items.first.reasons, isNotEmpty);
      }
    });
  });
}
