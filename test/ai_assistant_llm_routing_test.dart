import 'package:college_reality_india/features/assistant/services/ai_assistant_service.dart';
import 'package:college_reality_india/features/assistant/services/ai_chat_backend_client.dart';
import 'package:college_reality_india/features/assistant/services/ai_college_data_service.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/repositories/college_repository.dart';
import 'package:college_reality_india/features/community_feed/repositories/college_community_feed_repository.dart';
import 'package:college_reality_india/features/questions/repositories/question_repository.dart';
import 'package:college_reality_india/features/reviews/repositories/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers the hybrid DB-vs-LLM routing decision (spec: "don't call the LLM
/// for every simple database question") and the LLM-unavailable fallback
/// (spec: "fallback to the existing database/search answer system"),
/// using a fully controllable fake AiChatBackendClient rather than relying
/// on Firebase being genuinely unreachable in tests.
class _FakeCollegeRepository implements CollegeRepository {
  _FakeCollegeRepository(this.colleges);
  final List<CollegeModel> colleges;

  @override
  Future<CollegeModel?> getCollegeById(String id) async =>
      colleges.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<CollegeModel>> getCollegesByIds(List<String> ids) async =>
      colleges.where((c) => ids.contains(c.id)).toList();

  @override
  Future<List<CollegeModel>> autocomplete(String query) async => const [];

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
  }) async =>
      CollegeSearchPage(colleges: colleges);

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
  Future<CollegeDirectoryMeta> getDirectoryMeta() async => const CollegeDirectoryMeta();

  @override
  Future<int> getCollegeCount({bool activeOnly = true}) async => colleges.length;

  @override
  Future<List<CollegeModel>> getFeaturedColleges({int limit = 10}) async => colleges;

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

/// Fully controllable stand-in for the real Cloud-Function-backed client --
/// records every call and returns/throws whatever the test configures,
/// with zero dependency on Firebase.
class _FakeAiChatBackendClient implements AiChatBackendClient {
  int callCount = 0;
  String? lastQuestion;
  String? lastMode;
  Object? throwOnComplete;
  AiChatBackendResult response = const AiChatBackendResult(
    text: 'LLM-generated answer',
    cached: false,
    isGeneralAdvice: false,
  );

  @override
  Future<AiChatBackendResult> complete({
    required String question,
    required String mode,
    String? collegeId,
    Map<String, dynamic>? collegeContext,
    List<Map<String, dynamic>>? candidateColleges,
    List<Map<String, String>>? history,
    Map<String, String?>? filters,
  }) async {
    callCount++;
    lastQuestion = question;
    lastMode = mode;
    if (throwOnComplete != null) throw throwOnComplete!;
    return response;
  }
}

CollegeModel _sampleCollege() {
  return CollegeModel(
    id: 'c1',
    name: 'Test Engineering College',
    nameLower: 'test engineering college',
    slug: 'c1',
    city: 'Pune',
    cityLower: 'pune',
    district: 'Pune',
    districtLower: 'pune',
    state: 'Maharashtra',
    stateLower: 'maharashtra',
    address: 'Test address',
    type: 'private',
    courses: const ['B.Tech'],
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
  late _FakeAiChatBackendClient chatBackend;
  late AiAssistantService service;
  late CollegeModel college;

  setUp(() {
    college = _sampleCollege();
    final collegeRepo = _FakeCollegeRepository([college]);
    final dataService = AiCollegeDataService(
      collegeRepo,
      _MockReviewRepository(),
      _MockQuestionRepository(),
      _MockCollegeCommunityFeedRepository(),
    );
    chatBackend = _FakeAiChatBackendClient();
    service = AiAssistantService(collegeRepo, dataService, chatBackend);
  });

  group('DB-only routing (cost control)', () {
    for (final q in ['How are placements?', 'What are the fees?', 'Is hostel available?']) {
      test('"$q" never calls the LLM', () async {
        final result = await service.askAboutCollege(college: college, question: q);
        expect(chatBackend.callCount, 0, reason: 'a simple factual question must stay DB-only');
        expect(result.text, isNotEmpty);
        expect(result.isGeneralAdvice, isFalse);
      });
    }
  });

  group('LLM routing for open-ended questions', () {
    test('an open-ended question calls the LLM with the grounded bundle as context', () async {
      final result = await service.askAboutCollege(
        college: college,
        question: 'How is student life here?',
      );
      expect(chatBackend.callCount, 1);
      expect(chatBackend.lastMode, 'college');
      expect(result.text, 'LLM-generated answer');
    });

    test('general discovery search calls the LLM once real candidates are found', () async {
      final result = await service.processQuery(query: 'Best colleges in Pune');
      expect(chatBackend.callCount, 1);
      expect(chatBackend.lastMode, 'explore');
      expect(result.text, 'LLM-generated answer');
    });
  });

  group('LLM fallback when the backend is unavailable', () {
    test('falls back to the grounded database answer on any non-quota failure', () async {
      chatBackend.throwOnComplete = Exception('network unreachable');
      final result = await service.askAboutCollege(
        college: college,
        question: 'Tell me about this college',
      );
      expect(chatBackend.callCount, 1);
      // Still got a real, non-empty answer -- the app never went blank or
      // crashed just because the LLM call failed.
      expect(result.text, isNotEmpty);
      expect(result.text, isNot('LLM-generated answer'));
    });

    test('a quota-exceeded failure propagates instead of silently falling back', () async {
      chatBackend.throwOnComplete =
          const AiChatQuotaExceededException("You've reached today's AI chat limit.");
      expect(
        () => service.askAboutCollege(college: college, question: 'Tell me about this college'),
        throwsA(isA<AiChatQuotaExceededException>()),
      );
    });
  });
}
