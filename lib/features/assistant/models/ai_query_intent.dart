enum AiQueryType {
  search,
  compare,
  question,
  unknown,
}

enum AiSortPriority {
  overall,
  placements,
  feesLow,
  hostel,
  campusLife,
  attendance,
  faculty,
  naac,
  nirf,
}

class AiQueryIntent {
  final AiQueryType type;
  final String rawQuery;
  final String? city;
  final String? state;
  final String? course;
  final String? collegeType;
  final String? naacGrade;
  final int? maxFees;
  final int? minFees;
  final bool requireHostel;
  final bool nearMe;
  final AiSortPriority sortBy;
  final List<String> compareCollegeIds;
  final String? comparisonMetric;
  final List<String> detectedLanguages;

  const AiQueryIntent({
    this.type = AiQueryType.search,
    required this.rawQuery,
    this.city,
    this.state,
    this.course,
    this.collegeType,
    this.naacGrade,
    this.maxFees,
    this.minFees,
    this.requireHostel = false,
    this.nearMe = false,
    this.sortBy = AiSortPriority.overall,
    this.compareCollegeIds = const [],
    this.comparisonMetric,
    this.detectedLanguages = const ['en'],
  });

  bool get hasLocationFilter => city != null || state != null || nearMe;
}
