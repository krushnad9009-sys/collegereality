import 'review_model.dart';

/// Rating distribution buckets (1–5 stars) for college review summaries.
class RatingDistribution {
  final Map<int, int> buckets;

  const RatingDistribution({this.buckets = const {}});

  int get total => buckets.values.fold(0, (a, b) => a + b);

  int countFor(int stars) => buckets[stars] ?? 0;

  double fractionFor(int stars) {
    if (total == 0) return 0;
    return countFor(stars) / total;
  }

  factory RatingDistribution.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RatingDistribution();
    final result = <int, int>{};
    for (var i = 1; i <= 5; i++) {
      result[i] = (json['$i'] as num?)?.toInt() ?? 0;
    }
    return RatingDistribution(buckets: result);
  }

  Map<String, dynamic> toJson() {
    return {for (var i = 1; i <= 5; i++) '$i': countFor(i)};
  }

  RatingDistribution applyStar(int star, {required int delta}) {
    final clamped = star.clamp(1, 5);
    final next = Map<int, int>.from(buckets);
    next[clamped] = ((next[clamped] ?? 0) + delta).clamp(0, 999999);
    return RatingDistribution(buckets: next);
  }

  static int starBucketFor(double overallRating) {
    if (overallRating <= 0) return 3;
    return overallRating.round().clamp(1, 5);
  }
}

/// Running totals for O(1) aggregate updates — stored on college documents.
class ReviewAggregationMeta {
  final Map<String, double> dimensionSums;
  final Map<String, int> dimensionCounts;
  final Map<String, int> starDistribution;
  final Map<String, int> yesNoYesCounts;
  final Map<String, int> yesNoTotalCounts;
  final int reviewCount;

  const ReviewAggregationMeta({
    this.dimensionSums = const {},
    this.dimensionCounts = const {},
    this.starDistribution = const {},
    this.yesNoYesCounts = const {},
    this.yesNoTotalCounts = const {},
    this.reviewCount = 0,
  });

  factory ReviewAggregationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewAggregationMeta();
    return ReviewAggregationMeta(
      dimensionSums: (json['dimensionSums'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      dimensionCounts: (json['dimensionCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      starDistribution: (json['starDistribution'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      yesNoYesCounts: (json['yesNoYesCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      yesNoTotalCounts: (json['yesNoTotalCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'dimensionSums': dimensionSums,
        'dimensionCounts': dimensionCounts,
        'starDistribution': starDistribution,
        'yesNoYesCounts': yesNoYesCounts,
        'yesNoTotalCounts': yesNoTotalCounts,
        'reviewCount': reviewCount,
      };
}

class ReviewPage {
  final List<ReviewModel> reviews;
  final String? lastDocumentId;
  final bool hasMore;

  const ReviewPage({
    required this.reviews,
    this.lastDocumentId,
    this.hasMore = false,
  });
}
