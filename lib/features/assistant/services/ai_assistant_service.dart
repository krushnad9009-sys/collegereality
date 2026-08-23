import 'package:flutter/foundation.dart';

import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/repositories/college_repository.dart';
import '../../colleges/utils/college_search_utils.dart';
import '../../ranking/models/ranking_models.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../ranking/utils/smart_recommendation_engine.dart';
import '../models/ai_assistant_message.dart';
import '../models/ai_college_data_bundle.dart';
import '../models/ai_college_recommendation.dart';
import '../models/ai_query_intent.dart';
import '../models/ai_topic.dart';
import 'ai_chat_backend_client.dart';
import 'ai_college_data_service.dart';
import 'ai_college_ranker.dart';
import 'ai_comparison_service.dart';
import 'ai_explanation_builder.dart';
import 'ai_grounded_answer_builder.dart';
import 'ai_query_parser.dart';
import 'ai_suggestion_service.dart';
import 'ai_topic_detector.dart';

/// Orchestrates NL parsing → Firestore fetch → rank → grounded explain, and
/// — for genuinely ambiguous/open-ended/reasoning-heavy questions only —
/// hands compact, pre-retrieved verified data to the LLM backend
/// (AiChatBackendClient → Cloud Function → Gemini) for natural-language
/// reasoning. Simple factual lookups (fees/hostel/placements/etc, when
/// verified data actually answers them) never touch the LLM at all — see
/// _answerAboutCollege and processQuery's search branch for exactly where
/// that decision is made and why.
class AiAssistantService {
  AiAssistantService(
    this._collegeRepository,
    this._collegeDataService, [
    AiChatBackendClient? chatBackend,
  ]) : _chatBackend = chatBackend ?? AiChatBackendClient();

  final CollegeRepository _collegeRepository;
  final AiCollegeDataService _collegeDataService;
  final AiChatBackendClient _chatBackend;
  final AiQueryParser _parser = AiQueryParser();
  final AiCollegeRanker _ranker = AiCollegeRanker();
  final AiExplanationBuilder _explanationBuilder = AiExplanationBuilder();
  final AiComparisonService _comparisonService = AiComparisonService();
  final AiSuggestionService _suggestionService = AiSuggestionService();

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AiAssistantService] $message');
  }
  final AiTopicDetector _topicDetector = AiTopicDetector();
  final AiGroundedAnswerBuilder _groundedBuilder = AiGroundedAnswerBuilder();

  Future<AiAssistantMessage> processQuery({
    required String query,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    String? conversationCity,
    String? conversationState,
    CollegeModel? anchorCollege,
    AiAssistantMode mode = AiAssistantMode.chat,
    List<AiAssistantMessage> history = const [],
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
      conversationCity: conversationCity,
      conversationState: conversationState,
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
        history: history,
      );
    }

    // A query naming an explicit city/state (e.g. "best engineering college
    // in Mumbai") is a list/ranking request, never a lookup for one
    // specific named college -- skip the single-college resolver entirely
    // so it can't hijack a location-scoped question into an answer about
    // one arbitrary (and possibly wrong-city) college.
    final hasExplicitLocation = intent.city != null || intent.state != null;
    final resolvedCollege =
        hasExplicitLocation ? null : await _resolveCollegeFromQuery(query);
    if (resolvedCollege != null && _isCollegeSpecificQuestion(query, topic)) {
      return _answerAboutCollege(
        college: resolvedCollege,
        question: query,
        contextCollegeIds: contextCollegeIds,
        userCity: userCity,
        userState: userState,
        mode: mode,
        history: history,
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

    // Final safety dedupe by college id.
    final uniqueRecommendations = <String, AiCollegeRecommendation>{};
    for (final rec in withReasons) {
      uniqueRecommendations.putIfAbsent(rec.college.id, () => rec);
    }
    final dedupedRecommendations = uniqueRecommendations.values.toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    for (var i = 0; i < dedupedRecommendations.length; i++) {
      dedupedRecommendations[i] = AiCollegeRecommendation(
        college: dedupedRecommendations[i].college,
        score: dedupedRecommendations[i].score,
        rank: i + 1,
        reasons: dedupedRecommendations[i].reasons,
      );
    }

    final suggestions = _suggestionService.buildSuggestions(
      topResults: dedupedRecommendations,
      allCandidates: filtered,
      intent: intent,
      anchorCollege: anchorCollege,
    );

    var summary = _explanationBuilder.buildSearchSummary(
      intent,
      dedupedRecommendations.length,
    );
    var isGeneralAdvice = false;

    // Discovery/ranking questions ("best colleges in X", budget-constrained,
    // "good for CSE") are exactly the reasoning-over-multiple-results case
    // the LLM is for -- but only when there's something real to reason
    // about; a zero-result reply is already complete and correct as-is, so
    // skip the LLM call entirely rather than asking it to explain nothing.
    if (dedupedRecommendations.isNotEmpty) {
      try {
        final llmResult = await _chatBackend.complete(
          question: query,
          mode: 'explore',
          candidateColleges: dedupedRecommendations
              .map((r) => _candidateContext(r.college))
              .toList(),
          history: _historyContext(history),
          filters: {'city': intent.city, 'state': intent.state, 'course': intent.course},
        );
        summary = llmResult.text;
        isGeneralAdvice = llmResult.isGeneralAdvice;
      } on AiChatQuotaExceededException {
        rethrow;
      } catch (e) {
        _log('LLM enhancement failed for search summary, using templated summary: $e');
      }
    }

    return AiAssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: AiMessageRole.assistant,
      text: summary,
      recommendations: dedupedRecommendations,
      suggestions: suggestions,
      createdAt: DateTime.now(),
      dataGrounded: true,
      mode: mode,
      isGeneralAdvice: isGeneralAdvice,
      // Only stamped when this reply actually matched something for that
      // location -- a zero-result "no colleges match X" reply must not
      // poison the next follow-up into silently reusing a location that
      // just proved to have no verified data.
      resolvedCity: dedupedRecommendations.isNotEmpty ? intent.city : null,
      resolvedState: dedupedRecommendations.isNotEmpty ? intent.state : null,
    );
  }

  Future<AiAssistantMessage> askAboutCollege({
    required CollegeModel college,
    required String question,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    AiAssistantMode mode = AiAssistantMode.chat,
    List<AiAssistantMessage> history = const [],
  }) =>
      _answerAboutCollege(
        college: college,
        question: question,
        contextCollegeIds: contextCollegeIds,
        userCity: userCity,
        userState: userState,
        mode: mode,
        history: history,
      );

  Future<AiAssistantMessage> _answerAboutCollege({
    required CollegeModel college,
    required String question,
    List<String> contextCollegeIds = const [],
    String? userCity,
    String? userState,
    AiAssistantMode mode = AiAssistantMode.chat,
    List<AiAssistantMessage> history = const [],
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
    _log('detected topic=$topic for question="$question"');
    _log('START fetchBundle(collegeId=${college.id})');
    final bundle = await _collegeDataService.fetchBundle(college.id);
    if (bundle == null) {
      _log('fetchBundle returned null -- no college doc found for ${college.id}');
      return _textReply('Could not load verified data for ${college.name}.');
    }
    _log(
      'SUCCESS fetchBundle -- reviews=${bundle.reviews.length} '
      'verifiedAnswers=${bundle.verifiedAnswers.length} '
      'communityPosts=${bundle.communityPosts.length}',
    );

    final grounded = _groundedBuilder.build(
      bundle: bundle,
      topic: topic,
      query: question,
    );
    _log('SUCCESS build grounded answer, sources=${grounded.sources.length}');

    // Cost control (spec's "don't call the LLM for every simple database
    // question"): the 7 specific factual topics already have a complete,
    // free, database-only answer above -- fees/hostel/placements/package/
    // faculty/campusLife/ragging never touch the LLM. Only genuinely
    // open-ended questions ("how is student life", "tell me about this
    // college", "is this college good") and stray exam-score phrasing that
    // landed here go to the LLM, and only to turn the SAME already-fetched
    // verified bundle into a natural reply -- never to invent new facts.
    final needsLlmReasoning = topic == AiTopic.general || topic == AiTopic.examScore;
    if (!needsLlmReasoning) {
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

    try {
      final llmResult = await _chatBackend.complete(
        question: question,
        mode: 'college',
        collegeId: college.id,
        collegeContext: _collegeContext(bundle),
        history: _historyContext(history),
      );
      return AiAssistantMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiMessageRole.assistant,
        text: llmResult.text,
        sources: grounded.sources,
        createdAt: DateTime.now(),
        dataGrounded: true,
        mode: mode,
        isGeneralAdvice: llmResult.isGeneralAdvice,
      );
    } on AiChatQuotaExceededException {
      rethrow;
    } catch (e) {
      _log('LLM enhancement failed for college question, falling back to grounded answer: $e');
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
  }

  /// Compact, cost-conscious college context for the LLM -- real verified
  /// fields only, capped review/answer excerpts, never the full bundle.
  Map<String, dynamic> _collegeContext(AiCollegeDataBundle bundle) {
    final college = bundle.college;
    final crScore = CrScoreEngine.effectiveScore(college);
    return {
      'name': college.name,
      'city': college.city,
      'state': college.state,
      'category': college.category,
      if (crScore > 0) 'crScore': crScore,
      if (college.fees.tuitionMin > 0) 'feesMin': college.fees.tuitionMin,
      if (college.fees.tuitionMax > 0) 'feesMax': college.fees.tuitionMax,
      if (college.placements.averagePackageLpa > 0)
        'avgPackageLpa': college.placements.averagePackageLpa,
      if (college.placements.highestPackageLpa > 0)
        'highestPackageLpa': college.placements.highestPackageLpa,
      if (college.placements.placementPercentage > 0)
        'placementPct': college.placements.placementPercentage,
      'hostelAvailable': college.hostel.available,
      'reviewExcerpts': bundle.reviews
          .where((r) => r.textReview.isNotEmpty)
          .take(3)
          .map((r) => r.textReview)
          .toList(),
      'verifiedAnswerExcerpts': bundle.verifiedAnswers
          .where((a) => a.answer.body.isNotEmpty)
          .take(3)
          .map((a) => a.answer.body)
          .toList(),
    };
  }

  Map<String, dynamic> _candidateContext(CollegeModel college) {
    final crScore = CrScoreEngine.effectiveScore(college);
    return {
      'id': college.id,
      'name': college.name,
      'city': college.city,
      'state': college.state,
      if (crScore > 0) 'crScore': crScore,
      if (college.placements.averagePackageLpa > 0)
        'avgPackageLpa': college.placements.averagePackageLpa,
      if (college.placements.placementPercentage > 0)
        'placementPct': college.placements.placementPercentage,
      if (college.fees.tuitionMin > 0) 'feesMin': college.fees.tuitionMin,
    };
  }

  // Deliberately small and independent of AiAssistantConstants
  // .maxConversationTurns (that constant bounds local on-device history
  // storage -- a much larger, unrelated concern). The server
  // (AI_CHAT_CONFIG.MAX_HISTORY_TURNS) independently re-caps this again.
  static const _maxLlmHistoryMessages = 6;

  /// Last few messages only, plain role/text pairs -- keeps the request
  /// small and controls cost.
  List<Map<String, String>> _historyContext(List<AiAssistantMessage> history) {
    return history
        .where((m) => m.text.isNotEmpty)
        .toList()
        .reversed
        .take(_maxLlmHistoryMessages)
        .toList()
        .reversed
        .map((m) => {
              'role': m.role == AiMessageRole.user ? 'user' : 'assistant',
              'text': m.text,
            })
        .toList();
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

    // An explicit city/state in the question is a hard constraint, not a
    // ranking preference -- it must never be silently dropped in favour of
    // an unrelated-location fallback below.
    final hasExplicitLocation = intent.city != null || intent.state != null;

    if (hasExplicitLocation || firestoreCourse != null) {
      final page = await _collegeRepository.searchColleges(
        city: intent.city,
        state: intent.state,
        course: firestoreCourse,
        limit: limit,
      );
      if (page.colleges.isNotEmpty) return page.colleges;

      // The course was too narrow for this location (e.g. a real city with
      // colleges, just none tagged with the exact course token) -- retry
      // keeping the location and dropping only the course, so a genuine
      // "engineering colleges in <real city>" still returns that city's
      // colleges instead of nothing.
      if (hasExplicitLocation && firestoreCourse != null) {
        final locationOnly = await _collegeRepository.searchColleges(
          city: intent.city,
          state: intent.state,
          limit: limit,
        );
        if (locationOnly.colleges.isNotEmpty) return locationOnly.colleges;
      }
    }

    // Location was explicitly requested but nothing matched it, even after
    // relaxing the course. Do NOT fall through to featured/global/name-hint
    // results below -- those ignore location entirely and are exactly how
    // "best engineering college in Mumbai" used to come back with Kanpur/
    // Bangalore/Pune colleges. Returning empty here means the caller
    // reports "no colleges match ... in Mumbai" instead.
    if (hasExplicitLocation) {
      _log(
        'no candidates matched explicit location city=${intent.city} '
        'state=${intent.state} -- returning empty rather than an '
        'unrelated-location fallback',
      );
      return const [];
    }

    if (intent.sortBy == AiSortPriority.placements ||
        intent.sortBy == AiSortPriority.overall) {
      return _collegeRepository.getFeaturedColleges(limit: limit);
    }

    final hints = _parser.extractCollegeNameHints(rawQuery);
    if (hints.isNotEmpty) {
      final found = <CollegeModel>[];
      final seen = <String>{};
      for (final hint in hints) {
        final results = await _collegeRepository.autocomplete(hint);
        for (final college in results) {
          if (seen.add(college.id)) found.add(college);
        }
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
      // Defense in depth: an explicit city/state must hold regardless of
      // which path fetched these candidates (Firestore query, featured
      // list, autocomplete hints...) -- reuses the same city-alias
      // matching (Mumbai/Bombay, Mumbai City, Greater Mumbai, etc. all
      // contain "mumbai") the rest of college search already relies on,
      // no new normalization logic and no data changes.
      if (intent.city != null &&
          !CollegeSearchUtils.cityMatchesCollege(
            cityLower: c.cityLower,
            districtLower: c.districtLower,
            cityFilter: intent.city!,
          )) {
        return false;
      }
      if (intent.state != null &&
          c.stateLower != CollegeSearchUtils.normalizeState(intent.state!)) {
        return false;
      }
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
