import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/repositories/college_repository.dart';
import '../../ranking/models/ranking_models.dart';
import '../../ranking/utils/smart_recommendation_engine.dart';
import '../models/ai_assistant_message.dart';
import '../models/ai_college_recommendation.dart';
import '../models/ai_query_intent.dart';
import '../models/ai_topic.dart';
import 'ai_college_data_service.dart';
import 'ai_college_ranker.dart';
import 'ai_comparison_service.dart';
import 'ai_explanation_builder.dart';
import 'ai_grounded_answer_builder.dart';
import 'ai_query_parser.dart';
import 'ai_suggestion_service.dart';
import 'ai_topic_detector.dart';

/// Orchestrates NL parsing → Firestore fetch → rank → grounded explain. No LLM.
class AiAssistantService {
  AiAssistantService(this._collegeRepository, this._collegeDataService);

  final CollegeRepository _collegeRepository;
  final AiCollegeDataService _collegeDataService;
  final AiQueryParser _parser = AiQueryParser();
  final AiCollegeRanker _ranker = AiCollegeRanker();
  final AiExplanationBuilder _explanationBuilder = AiExplanationBuilder();
  final AiComparisonService _comparisonService = AiComparisonService();
  final AiSuggestionService _suggestionService = AiSuggestionService();
  final AiTopicDetector _topicDetector = AiTopicDetector();
  final AiGroundedAnswerBuilder _groundedBuilder = AiGroundedAnswerBuilder();

  Future<AiAssistantMessage> processQuery({
    required String query,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    CollegeModel? anchorCollege,
    AiAssistantMode mode = AiAssistantMode.chat,
  }) async {
    final hasContext =
        contextCollegeIds.isNotEmpty || anchorCollege != null;

    if (!_topicDetector.isCollegeRelated(query, hasCollegeContext: hasContext)) {
      return _textReply(_topicDetector.offTopicMessage());
    }

    final intent = _parser.parse(
      query,
      contextCollegeIds: contextCollegeIds,
      userCity: userCity,
      userState: userState,
    );

    if (mode == AiAssistantMode.compare ||
        intent.type == AiQueryType.compare ||
        (intent.type == AiQueryType.question && contextCollegeIds.length >= 2)) {
      return _handleComparison(query, intent, contextCollegeIds, mode);
    }

    final topic = _topicDetector.detectTopic(query);
    if (topic == AiTopic.examScore) {
      return _handleExamScoreQuery(query, intent, userState);
    }

    if (anchorCollege != null) {
      return _answerAboutCollege(
        college: anchorCollege,
        question: query,
        contextCollegeIds: contextCollegeIds,
        userCity: userCity,
        userState: userState,
        mode: mode,
      );
    }

    final resolvedCollege = await _resolveCollegeFromQuery(query);
    if (resolvedCollege != null && _isCollegeSpecificQuestion(query, topic)) {
      return _answerAboutCollege(
        college: resolvedCollege,
        question: query,
        contextCollegeIds: contextCollegeIds,
        userCity: userCity,
        userState: userState,
        mode: mode,
      );
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
      mode: mode,
    );
  }

  Future<AiAssistantMessage> askAboutCollege({
    required CollegeModel college,
    required String question,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    AiAssistantMode mode = AiAssistantMode.chat,
  }) =>
      _answerAboutCollege(
        college: college,
        question: question,
        contextCollegeIds: contextCollegeIds,
        userCity: userCity,
        userState: userState,
        mode: mode,
      );

  Future<AiAssistantMessage> _answerAboutCollege({
    required CollegeModel college,
    required String question,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    AiAssistantMode mode = AiAssistantMode.chat,
  }) async {
    final ids = [college.id, ...contextCollegeIds.where((id) => id != college.id)];
    final intent = _parser.parse(
      question,
      contextCollegeIds: ids,
      userCity: userCity,
      userState: userState,
    );

    if (mode == AiAssistantMode.compare ||
        intent.type == AiQueryType.compare ||
        question.toLowerCase().contains('compare') ||
        question.toLowerCase().contains('better')) {
      return _handleComparison(
        question,
        intent,
        ids.take(AiAssistantConstants.maxCompareColleges).toList(),
        mode,
      );
    }

    final topic = _topicDetector.detectTopic(question);
    final bundle = await _collegeDataService.fetchBundle(college.id);
    if (bundle == null) {
      return _textReply('Could not load verified data for ${college.name}.');
    }

    final grounded = _groundedBuilder.build(
      bundle: bundle,
      topic: topic,
      query: question,
    );

    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: grounded.text,
      sources: grounded.sources,
      createdAt: DateTime.now(),
      dataGrounded: true,
      mode: mode,
    );
  }

  Future<AiAssistantMessage> _handleExamScoreQuery(
    String query,
    AiQueryIntent intent,
    String? userState,
  ) async {
    final exam = _topicDetector.extractExamScore(query);
    if (exam == null) {
      return _textReply(
        'Please include your exam score, e.g. "JEE rank 15000" or "CET percentile 92".',
      );
    }

    final candidates = await _fetchCandidates(intent, query);
    final criteria = SmartRecommendationCriteria(
      examType: exam.examType,
      examScore: exam.score,
      preferredState: userState,
      branchPreference: intent.course,
      preferPlacements: true,
    );

    final picks = recommendColleges(
      colleges: candidates,
      criteria: criteria,
      limit: AiAssistantConstants.maxRecommendations,
    );

    if (picks.isEmpty) {
      return _textReply(
        'No colleges in our database match your ${exam.examType.toUpperCase()} '
        'score tier. Try broadening location or course filters.',
      );
    }

    final recommendations = picks
        .asMap()
        .entries
        .map(
          (e) => AiCollegeRecommendation(
            college: e.value.college,
            score: e.value.matchScore.toDouble(),
            rank: e.key + 1,
            reasons: e.value.reasons,
          ),
        )
        .toList();

    final examLabel = exam.examType == RankingConstants.examCet
        ? 'percentile ${exam.score}'
        : 'rank ${exam.score}';

    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: 'Best matches for ${exam.examType.toUpperCase()} $examLabel '
          'using verified placement, fees, and rating data:',
      recommendations: recommendations,
      createdAt: DateTime.now(),
      dataGrounded: true,
    );
  }

  Future<AiAssistantMessage> _handleComparison(
    String query,
    AiQueryIntent intent,
    List<String> contextCollegeIds,
    AiAssistantMode mode,
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
      return _textReply(
        'Compare mode: search for colleges first or name two colleges '
        '(e.g. "COEP vs VIT Pune"). Up to ${AiAssistantConstants.maxCompareColleges} colleges.',
        mode: mode,
      );
    }

    final colleges = await _collegeRepository.getCollegesByIds(collegeIds);
    if (colleges.length < 2) {
      return _textReply(
        'Need at least 2 colleges in our database to compare. '
        'Add colleges to compare or name them in your message.',
        mode: mode,
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
      mode: mode,
    );
  }

  Future<CollegeModel?> _resolveCollegeFromQuery(String query) async {
    final hints = _parser.extractCollegeNameHints(query);
    if (hints.isNotEmpty) {
      final results = await _collegeRepository.autocomplete(hints.first);
      if (results.isNotEmpty) return results.first;
    }

    final words = query.trim().split(RegExp(r'\s+')).where((w) => w.length > 4).toList();
    if (words.length >= 2) {
      final phrase = words.take(4).join(' ');
      final results = await _collegeRepository.autocomplete(phrase);
      if (results.length == 1) return results.first;
    }
    return null;
  }

  bool _isCollegeSpecificQuestion(String query, AiTopic topic) {
    if (topic != AiTopic.general) return true;
    final q = query.toLowerCase();
    return q.contains('this college') ||
        q.contains('is it good') ||
        q.contains('how is') ||
        q.contains('how are') ||
        q.contains('review') ||
        q.contains('?');
  }

  AiAssistantMessage _textReply(String text, {AiAssistantMode mode = AiAssistantMode.chat}) {
    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: text,
      createdAt: DateTime.now(),
      dataGrounded: true,
      mode: mode,
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
