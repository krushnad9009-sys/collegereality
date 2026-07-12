import 'dart:math';

import '../../colleges/models/college_model.dart';
import '../models/ai_college_recommendation.dart';
import '../models/ai_query_intent.dart';
import '../models/ai_suggestion_group.dart';
import 'ai_college_ranker.dart';
import 'ai_explanation_builder.dart';
import 'ai_query_parser.dart';

/// Generates similar, better, budget, and nearby alternatives from verified data.
class AiSuggestionService {
  final AiCollegeRanker _ranker = AiCollegeRanker();
  final AiExplanationBuilder _explanationBuilder = AiExplanationBuilder();
  final AiQueryParser _parser = AiQueryParser();

  List<AiSuggestionGroup> buildSuggestions({
    required List<AiCollegeRecommendation> topResults,
    required List<CollegeModel> allCandidates,
    required AiQueryIntent intent,
    CollegeModel? anchorCollege,
  }) {
    if (topResults.isEmpty && anchorCollege == null) return [];

    final anchor = anchorCollege ?? topResults.first.college;
    final groups = <AiSuggestionGroup>[];

    final similar = _similarColleges(anchor, allCandidates);
    if (similar.isNotEmpty) {
      groups.add(AiSuggestionGroup(
        type: AiSuggestionType.similar,
        title: 'Similar Colleges',
        items: similar,
      ));
    }

    final better = _betterAlternatives(anchor, allCandidates, intent);
    if (better.isNotEmpty) {
      groups.add(AiSuggestionGroup(
        type: AiSuggestionType.betterAlternative,
        title: 'Better Alternatives',
        items: better,
      ));
    }

    final budget = _budgetAlternatives(anchor, allCandidates);
    if (budget.isNotEmpty) {
      groups.add(AiSuggestionGroup(
        type: AiSuggestionType.budgetAlternative,
        title: 'Budget Alternatives',
        items: budget,
      ));
    }

    final nearby = _nearbyAlternatives(anchor, allCandidates);
    if (nearby.isNotEmpty) {
      groups.add(AiSuggestionGroup(
        type: AiSuggestionType.nearbyAlternative,
        title: 'Nearby Alternatives',
        items: nearby,
      ));
    }

    return groups;
  }

  List<AiCollegeRecommendation> _similarColleges(
    CollegeModel anchor,
    List<CollegeModel> candidates,
  ) {
    final filtered = candidates.where((c) {
      if (c.id == anchor.id) return false;
      final sameState = c.state == anchor.state;
      final sameType = c.type == anchor.type;
      final courseOverlap = c.courses.toSet().intersection(anchor.courses.toSet()).isNotEmpty;
      return sameState && (sameType || courseOverlap);
    }).toList();

    final intent = _parser.parse('similar colleges');
    final ranked = _ranker.rank(filtered, intent, limit: 4);
    return _withReasons(ranked, intent);
  }

  List<AiCollegeRecommendation> _betterAlternatives(
    CollegeModel anchor,
    List<CollegeModel> candidates,
    AiQueryIntent intent,
  ) {
    final anchorScore = _ranker.score(anchor, intent);
    final filtered = candidates.where((c) {
      if (c.id == anchor.id) return false;
      return _ranker.score(c, intent) > anchorScore &&
          c.aggregatedRatings.overall >= anchor.aggregatedRatings.overall;
    }).toList();

    final ranked = _ranker.rank(filtered, intent, limit: 4);
    return _withReasons(ranked, intent);
  }

  List<AiCollegeRecommendation> _budgetAlternatives(
    CollegeModel anchor,
    List<CollegeModel> candidates,
  ) {
    final anchorFee = _averageFee(anchor);
    if (anchorFee <= 0) return [];

    final intent = _parser.parse('budget colleges');
    final filtered = candidates.where((c) {
      if (c.id == anchor.id) return false;
      final fee = _averageFee(c);
      return fee > 0 && fee < anchorFee * 0.85;
    }).toList();

    final ranked = _ranker.rank(filtered, intent, limit: 4);
    return _withReasons(ranked, intent);
  }

  List<AiCollegeRecommendation> _nearbyAlternatives(
    CollegeModel anchor,
    List<CollegeModel> candidates,
  ) {
    final intent = _parser.parse('nearby colleges');
    final sameCity = candidates.where((c) {
      if (c.id == anchor.id) return false;
      return c.city.toLowerCase() == anchor.city.toLowerCase();
    }).toList();

    if (sameCity.isNotEmpty) {
      final ranked = _ranker.rank(sameCity, intent, limit: 4);
      return _withReasons(ranked, intent);
    }

    if (anchor.latitude != null && anchor.longitude != null) {
      final withDistance = candidates.where((c) {
        if (c.id == anchor.id) return false;
        return c.latitude != null && c.longitude != null;
      }).map((c) {
        return MapEntry(
          c,
          _haversineKm(
            anchor.latitude!,
            anchor.longitude!,
            c.latitude!,
            c.longitude!,
          ),
        );
      }).toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final nearby = withDistance
          .where((e) => e.value <= 100)
          .map((e) => e.key)
          .take(4)
          .toList();

      final ranked = _ranker.rank(nearby, intent, limit: 4);
      return _withReasons(ranked, intent);
    }

    final sameState = candidates.where((c) {
      if (c.id == anchor.id) return false;
      return c.state == anchor.state;
    }).toList();
    final ranked = _ranker.rank(sameState, intent, limit: 4);
    return _withReasons(ranked, intent);
  }

  List<AiCollegeRecommendation> _withReasons(
    List<AiCollegeRecommendation> items,
    AiQueryIntent intent,
  ) {
    return items
        .map(
          (r) => AiCollegeRecommendation(
            college: r.college,
            score: r.score,
            rank: r.rank,
            reasons: _explanationBuilder.buildReasons(r.college, intent),
          ),
        )
        .toList();
  }

  static int _averageFee(CollegeModel college) {
    final min = college.fees.tuitionMin;
    final max = college.fees.tuitionMax;
    if (min > 0 && max > 0) return ((min + max) / 2).round();
    return max > 0 ? max : min;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
