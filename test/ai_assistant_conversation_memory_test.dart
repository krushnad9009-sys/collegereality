import 'package:college_reality_india/features/assistant/services/ai_assistant_service.dart';
import 'package:college_reality_india/features/assistant/services/ai_college_data_service.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/repositories/college_repository.dart';
import 'package:college_reality_india/features/community_feed/repositories/college_community_feed_repository.dart';
import 'package:college_reality_india/features/questions/repositories/question_repository.dart';
import 'package:college_reality_india/features/reviews/repositories/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A small, real (non-mocked) in-memory CollegeRepository so this test
/// exercises the ACTUAL AiAssistantService/AiQueryParser pipeline end to
/// end -- parse -> Firestore-shaped fetch -> client filter -> rank ->
/// grounded reply -- for the new general-chat conversation-memory feature,
/// without needing a live Firebase project or an authenticated browser
/// session (this sandbox cannot reach the login-gated /assistant route
/// live -- see the final report).
class _FakeCollegeRepository implements CollegeRepository {
  _FakeCollegeRepository(this.colleges);

  final List<CollegeModel> colleges;

  bool _cityMatches(CollegeModel c, String? city) {
    if (city == null) return true;
    return c.city.toLowerCase() == city.toLowerCase();
  }

  bool _courseMatches(CollegeModel c, String? course) {
    if (course == null) return true;
    return c.courses.any((x) => x.toLowerCase().contains(course.toLowerCase())) ||
        (course.toLowerCase().contains('computer') &&
            c.courses.any((x) => x.toLowerCase().contains('computer')));
  }

  @override
  Future<CollegeSearchPage> searchColleges({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? startAfterDocumentId,
    int limit = 24,
    bool includeInactive = false,
  }) async {
    final matched = colleges
        .where((c) => _cityMatches(c, city) && _courseMatches(c, course))
        .toList();
    return CollegeSearchPage(colleges: matched);
  }

  @override
  Future<CollegeSearchPage> searchAllMatching({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    bool includeInactive = false,
  }) async =>
      CollegeSearchPage(colleges: colleges);

  @override
  Future<int> countSearchMatches({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
  }) async =>
      colleges.length;

  @override
  Future<List<CollegeModel>> autocomplete(String query) async => const [];

  @override
  Future<CollegeDirectoryMeta> getDirectoryMeta() async =>
      const CollegeDirectoryMeta();

  @override
  Future<int> getCollegeCount({bool activeOnly = true}) async =>
      colleges.length;

  @override
  Future<List<CollegeModel>> getFeaturedColleges({int limit = 10}) async =>
      colleges;

  @override
  Future<CollegeModel?> getCollegeById(String id) async =>
      colleges.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<CollegeModel>> getCollegesByIds(List<String> ids) async =>
      colleges.where((c) => ids.contains(c.id)).toList();

  @override
  Future<void> createCollege(CollegeModel college) async {}

  @override
  Future<void> updateCollege(CollegeModel college, {String? updatedBy}) async {}

  @override
  Future<void> setCollegeActive(String id, {required bool isActive}) async {}
}

class _MockReviewRepository extends Mock implements ReviewRepository {}

class _MockQuestionRepository extends Mock implements QuestionRepository {}

class _MockCollegeCommunityFeedRepository extends Mock
    implements CollegeCommunityFeedRepository {}

CollegeModel _college({
  required String id,
  required String name,
  required String city,
  required String state,
  List<String> courses = const ['B.Tech'],
}) {
  return CollegeModel(
    id: id,
    name: name,
    nameLower: name.toLowerCase(),
    slug: id,
    city: city,
    cityLower: city.toLowerCase(),
    district: city,
    districtLower: city.toLowerCase(),
    state: state,
    stateLower: state.toLowerCase(),
    address: '$city address',
    type: 'private',
    courses: courses,
    fees: const CollegeFees(tuitionMin: 100000, tuitionMax: 200000, hostelAnnual: 50000),
    placements: const CollegePlacements(
      highestPackageLpa: 12,
      averagePackageLpa: 6,
      placementPercentage: 80,
    ),
    accreditation: const CollegeAccreditation(),
    aggregatedRatings: const CollegeRatings(
      overall: 4,
      teaching: 4,
      placements: 4,
      faculty: 4,
      hostel: 4,
      food: 4,
      infrastructure: 4,
      campusLife: 4,
      attendance: 4,
      sports: 4,
      fees: 4,
    ),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late AiAssistantService service;

  setUp(() {
    final colleges = [
      _college(
        id: 'pune-1',
        name: 'Pune Engineering College',
        city: 'Pune',
        state: 'Maharashtra',
        courses: const ['B.Tech', 'Computer Engineering'],
      ),
      _college(
        id: 'nagpur-1',
        name: 'Nagpur Institute of Technology',
        city: 'Nagpur',
        state: 'Maharashtra',
        courses: const ['B.Tech'],
      ),
    ];
    final collegeRepo = _FakeCollegeRepository(colleges);
    final dataService = AiCollegeDataService(
      collegeRepo,
      _MockReviewRepository(),
      _MockQuestionRepository(),
      _MockCollegeCommunityFeedRepository(),
    );
    service = AiAssistantService(collegeRepo, dataService);
  });

  test(
    'general-chat follow-up with no location stays scoped via conversation memory',
    () async {
      final first = await service.processQuery(
        query: 'Best colleges in Pune',
      );
      expect(first.recommendations, isNotEmpty);
      expect(
        first.recommendations.every((r) => r.college.city == 'Pune'),
        isTrue,
      );
      expect(first.resolvedCity, 'Pune');

      // Follow-up names no location at all -- must still be scoped to Pune
      // via conversationCity, exactly like AiAssistantNotifier now passes
      // forward between turns.
      final followUp = await service.processQuery(
        query: 'What about CSE?',
        conversationCity: first.resolvedCity,
        conversationState: first.resolvedState,
      );
      expect(followUp.recommendations, isNotEmpty);
      expect(
        followUp.recommendations.every((r) => r.college.city == 'Pune'),
        isTrue,
        reason: 'follow-up must stay scoped to Pune without repeating it',
      );
    },
  );

  test(
    'an explicit new location in a follow-up overrides conversation memory',
    () async {
      final first = await service.processQuery(query: 'Best colleges in Pune');

      final pivot = await service.processQuery(
        query: 'Best colleges in Nagpur',
        conversationCity: first.resolvedCity,
        conversationState: first.resolvedState,
      );
      expect(
        pivot.recommendations.every((r) => r.college.city == 'Nagpur'),
        isTrue,
        reason: 'an explicitly named new city must always win over memory',
      );
    },
  );

  test(
    'a zero-result reply never poisons the next unrelated follow-up',
    () async {
      // Mumbai is a recognized city in the parser's alias list, but this
      // test's fake dataset only has Pune/Nagpur colleges -- a real
      // zero-verified-data-for-this-location case.
      final noData = await service.processQuery(
        query: 'Best colleges in Mumbai',
      );
      expect(noData.recommendations, isEmpty);
      expect(
        noData.resolvedCity,
        isNull,
        reason: 'a reply that found nothing must not be remembered',
      );
    },
  );
}
