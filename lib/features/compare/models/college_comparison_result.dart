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

class CollegeComparisonResult {
  final List<CollegeModel> colleges;
  final List<ComparisonRow> rows;
  final List<CollegeCompareInsight> insights;
  final String summary;
  final int? overallWinnerIndex;

  const CollegeComparisonResult({
    required this.colleges,
    required this.rows,
    this.insights = const [],
    required this.summary,
    this.overallWinnerIndex,
  });
}
