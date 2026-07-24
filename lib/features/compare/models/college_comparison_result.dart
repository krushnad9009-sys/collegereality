import '../../colleges/models/college_model.dart';

class ComparisonRow {
  final String metric;
  final String category;
  final List<String> values;
  final int? winnerIndex;
  final bool higherIsBetter;

  const ComparisonRow({
    required this.metric,
    this.category = 'General',
    required this.values,
    this.winnerIndex,
    this.higherIsBetter = true,
  });
}

class CollegeCompareInsight {
  final String collegeId;
  final String collegeName;
  final List<String> strengths;
  final List<String> weaknesses;

  const CollegeCompareInsight({
    required this.collegeId,
    required this.collegeName,
    this.strengths = const [],
    this.weaknesses = const [],
  });
}

class CollegeProsCons {
  final String collegeId;
  final String collegeName;
  final List<String> pros;
  final List<String> cons;

  const CollegeProsCons({
    required this.collegeId,
    required this.collegeName,
    this.pros = const [],
    this.cons = const [],
  });
}

class CompareAiSummary {
  final String? bestForPlacements;
  final String? bestForCampusLife;
  final String? bestValueForMoney;
  final String? bestOverall;

  const CompareAiSummary({
    this.bestForPlacements,
    this.bestForCampusLife,
    this.bestValueForMoney,
    this.bestOverall,
  });

  bool get hasAny =>
      bestForPlacements != null ||
      bestForCampusLife != null ||
      bestValueForMoney != null ||
      bestOverall != null;
}

class CollegeComparisonResult {
  final List<CollegeModel> colleges;
  final List<ComparisonRow> rows;
  final List<CollegeCompareInsight> insights;
  final List<CollegeProsCons> prosCons;
  final CompareAiSummary aiSummary;
  final String summary;
  final int? overallWinnerIndex;

  const CollegeComparisonResult({
    required this.colleges,
    required this.rows,
    this.insights = const [],
    this.prosCons = const [],
    this.aiSummary = const CompareAiSummary(),
    required this.summary,
    this.overallWinnerIndex,
  });
}
