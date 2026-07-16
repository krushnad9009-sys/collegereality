import '../../../core/constants/ai_assistant_constants.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/repositories/college_repository.dart';
import '../models/ai_assistant_message.dart';
import '../models/ai_college_recommendation.dart';
import '../models/ai_query_intent.dart';
import 'ai_college_ranker.dart';
import 'ai_comparison_service.dart';
import 'ai_explanation_builder.dart';
import 'ai_query_parser.dart';
import 'ai_suggestion_service.dart';

/// Orchestrates NL parsing → Firestore fetch → rank → explain. No LLM.
class AiAssistantService {
  final CollegeRepository _collegeRepository;
  final AiQueryParser _parser = AiQueryParser();
  final AiCollegeRanker _ranker = AiCollegeRanker();
  final AiExplanationBuilder _explanationBuilder = AiExplanationBuilder();
  final AiComparisonService _comparisonService = AiComparisonService();
  final AiSuggestionService _suggestionService = AiSuggestionService();

  AiAssistantService(this._collegeRepository);

  Future<AiAssistantMessage> processQuery({
    required String query,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    CollegeModel? anchorCollege,
  }) async {
    final intent = _parser.parse(
      query,
      contextCollegeIds: contextCollegeIds,
      userCity: userCity,
      userState: userState,
    );

    if (intent.type == AiQueryType.compare || intent.type == AiQueryType.question) {
      return _handleComparison(query, intent, contextCollegeIds);
    }

    final candidates = await _fetchCandidates(intent, query);
    final filtered = _applyClientFilters(candidates, intent);
    final ranked = _ranker.rank(
      filtered,
      intent,
      limit: AiAssistantConstants.maxRecommendations,
    );

    final withReasons = ranked
        .map(
          (r) => AiCollegeRecommendation(
            college: r.college,
            score: r.score,
            rank: r.rank,
            reasons: _explanationBuilder.buildReasons(r.college, intent),
          ),
        )
        .toList();

    final suggestions = _suggestionService.buildSuggestions(
      topResults: withReasons,
      allCandidates: filtered,
      intent: intent,
      anchorCollege: anchorCollege,
    );

    final summary = _explanationBuilder.buildSearchSummary(intent, withReasons.length);

    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: summary,
      recommendations: withReasons,
      suggestions: suggestions,
      createdAt: DateTime.now(),
      dataGrounded: true,
    );
  }

  Future<AiAssistantMessage> askAboutCollege({
    required CollegeModel college,
    required String question,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
  }) async {
    final ids = [college.id, ...contextCollegeIds.where((id) => id != college.id)];
    final intent = _parser.parse(
      question,
      contextCollegeIds: ids,
      userCity: userCity,
      userState: userState,
    );

    if (intent.type == AiQueryType.compare ||
        intent.type == AiQueryType.question ||
        question.toLowerCase().contains('compare') ||
        question.toLowerCase().contains('better')) {
      final compareIds = ids.take(AiAssistantConstants.maxCompareColleges).toList();
      return _handleComparison(question, intent, compareIds);
    }

    final similarIntent = _parser.parse('similar ${college.type} colleges in ${college.city}');
    final candidates = await _fetchCandidates(similarIntent, question);
    final filtered = _applyClientFilters(candidates, similarIntent)
      ..removeWhere((c) => c.id == college.id);

    final ranked = _ranker.rank(filtered, similarIntent, limit: 5);
    final withReasons = ranked
        .map(
          (r) => AiCollegeRecommendation(
            college: r.college,
            score: r.score,
            rank: r.rank,
            reasons: _explanationBuilder.buildReasons(r.college, similarIntent),
          ),
        )
        .toList();

    final suggestions = _suggestionService.buildSuggestions(
      topResults: withReasons,
      allCandidates: filtered,
      intent: similarIntent,
      anchorCollege: college,
    );

    final reasons = _explanationBuilder.buildReasons(college, intent);
    final text = 'About ${college.name}:\n${reasons.join('\n')}\n\n'
        '${withReasons.isNotEmpty ? 'Related alternatives:' : ''}';

    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: text,
      recommendations: withReasons,
      suggestions: suggestions,
      createdAt: DateTime.now(),
      dataGrounded: true,
    );
  }

  Future<AiAssistantMessage> _handleComparison(
    String query,
    AiQueryIntent intent,
    List<String> contextCollegeIds,
  ) async {
    var collegeIds = contextCollegeIds.take(AiAssistantConstants.maxCompareColleges).toList();

    if (collegeIds.length < 2) {
      final hints = _parser.extractCollegeNameHints(query);
      for (final hint in hints) {
        final results = await _collegeRepository.autocomplete(hint);
        for (final college in results) {
          if (!collegeIds.contains(college.id)) {
            collegeIds.add(college.id);
          }
        }
        if (collegeIds.length >= AiAssistantConstants.maxCompareColleges) break;
      }
    }

    if (collegeIds.isEmpty) {
      return AiAssistantMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiMessageRole.assistant,
        text: 'Please search for colleges first, then ask me to compare them '
            '(up to ${AiAssistantConstants.maxCompareColleges}).',
        createdAt: DateTime.now(),
        dataGrounded: true,
      );
    }

    final colleges = await _collegeRepository.getCollegesByIds(collegeIds);
    if (colleges.length < 2) {
      return AiAssistantMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiMessageRole.assistant,
        text: 'Need at least 2 colleges in our database to compare. '
            'Search and select colleges, then ask "which is better?"',
        createdAt: DateTime.now(),
        dataGrounded: true,
      );
    }

    final comparison = _comparisonService.compare(
      colleges,
      focusMetric: intent.comparisonMetric,
    );

    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: comparison.summary,
      comparison: comparison,
      createdAt: DateTime.now(),
      dataGrounded: true,
    );
  }

  Future<List<CollegeModel>> _fetchCandidates(
    AiQueryIntent intent,
    String rawQuery,
  ) async {
    final limit = AiAssistantConstants.candidateFetchLimit;
    String? firestoreCourse = intent.course;
    if (firestoreCourse == 'Computer Engineering') {
      firestoreCourse = null;
    }

    if (intent.city != null || intent.state != null || firestoreCourse != null) {
      final page = await _collegeRepository.searchColleges(
        city: intent.city,
        state: intent.state,
        course: firestoreCourse,
        limit: limit,
      );
      if (page.colleges.isNotEmpty) return page.colleges;
    }

    if (intent.sortBy == AiSortPriority.placements ||
        intent.sortBy == AiSortPriority.overall) {
      return _collegeRepository.getFeaturedColleges(limit: limit);
    }

    final hints = _parser.extractCollegeNameHints(rawQuery);
    if (hints.isNotEmpty) {
      final found = <CollegeModel>[];
      for (final hint in hints) {
        final results = await _collegeRepository.autocomplete(hint);
        found.addAll(results);
      }
      if (found.isNotEmpty) return found;
    }

    final page = await _collegeRepository.searchColleges(limit: limit);
    return page.colleges;
  }

  List<CollegeModel> _applyClientFilters(
    List<CollegeModel> colleges,
    AiQueryIntent intent,
  ) {
    return colleges.where((c) {
      if (intent.collegeType != null &&
          c.type.toLowerCase() != intent.collegeType!.toLowerCase()) {
        return false;
      }
      if (intent.requireHostel && !c.hostel.available) return false;
      if (intent.naacGrade != null) {
        final grade = c.accreditation.naacGrade?.replaceAll(' ', '').toUpperCase();
        final target = intent.naacGrade!.replaceAll(' ', '').toUpperCase();
        if (grade != target) return false;
      }
      if (intent.maxFees != null) {
        final fee = _averageFee(c);
        if (fee > 0 && fee > intent.maxFees!) return false;
      }
      if (intent.course == 'Computer Engineering') {
        final hasCse = c.displayCourses.any(
          (course) =>
              course.toLowerCase().contains('computer') ||
              course.toLowerCase().contains('cse') ||
              course.toLowerCase().contains('information technology'),
        );
        if (!hasCse) return false;
      }
      return true;
    }).toList();
  }

  static int _averageFee(CollegeModel college) {
    final min = college.fees.tuitionMin;
    final max = college.fees.tuitionMax;
    if (min > 0 && max > 0) return ((min + max) / 2).round();
    return max > 0 ? max : min;
  }
}
