import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/ranking_constants.dart';
import '../../colleges/models/college_model.dart';

class RankingPageResult {
  final List<CollegeModel> colleges;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const RankingPageResult({
    required this.colleges,
    this.lastDocument,
    this.hasMore = false,
  });
}

class CollegeRankEntry {
  final CollegeModel college;
  final double overallScore;
  final double categoryScore;
  final int rank;

  const CollegeRankEntry({
    required this.college,
    required this.overallScore,
    required this.categoryScore,
    required this.rank,
  });
}

class SmartRecommendationCriteria {
  final String examType;
  final int examScore;
  final String reservationCategory;
  final int? maxBudget;
  final String? preferredState;
  final String? preferredCity;
  final bool requireHostel;
  final bool preferPlacements;
  final String? branchPreference;

  const SmartRecommendationCriteria({
    this.examType = RankingConstants.examCet,
    this.examScore = 0,
    this.reservationCategory = 'General',
    this.maxBudget,
    this.preferredState,
    this.preferredCity,
    this.requireHostel = false,
    this.preferPlacements = true,
    this.branchPreference,
  });
}

class SmartRecommendationResult {
  final CollegeModel college;
  final int matchScore;
  final List<String> reasons;

  const SmartRecommendationResult({
    required this.college,
    required this.matchScore,
    this.reasons = const [],
  });
}

class CompareRecommendationItem {
  final CollegeModel college;
  final int rank;
  final double overallScore;
  final double roiScore;
  final String whyRecommended;
  final List<String> strengths;
  final List<String> weaknesses;
  final String expectedPlacement;
  final String feesLabel;

  const CompareRecommendationItem({
    required this.college,
    required this.rank,
    required this.overallScore,
    required this.roiScore,
    required this.whyRecommended,
    this.strengths = const [],
    this.weaknesses = const [],
    this.expectedPlacement = '',
    this.feesLabel = '',
  });
}

class CollegeInsightItem {
  final String insightType;
  final String title;
  final String description;
  final CollegeModel college;

  const CollegeInsightItem({
    required this.insightType,
    required this.title,
    required this.description,
    required this.college,
  });
}

class CollegeAnalyticsEntry {
  final CollegeModel college;
  final int metricValue;
  final String metricLabel;

  const CollegeAnalyticsEntry({
    required this.college,
    required this.metricValue,
    required this.metricLabel,
  });
}

class CollegeAnalyticsSnapshot {
  final List<CollegeAnalyticsEntry> popularColleges;
  final List<CollegeAnalyticsEntry> mostReviewed;
  final List<CollegeAnalyticsEntry> highestRated;
  final List<CollegeAnalyticsEntry> mostSearched;

  const CollegeAnalyticsSnapshot({
    this.popularColleges = const [],
    this.mostReviewed = const [],
    this.highestRated = const [],
    this.mostSearched = const [],
  });
}
