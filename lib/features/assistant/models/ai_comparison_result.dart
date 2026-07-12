import '../../colleges/models/college_model.dart';

class AiComparisonRow {
  final String metric;
  final List<String> values;
  final int? winnerIndex;

  const AiComparisonRow({
    required this.metric,
    required this.values,
    this.winnerIndex,
  });
}

class AiComparisonResult {
  final List<CollegeModel> colleges;
  final List<AiComparisonRow> rows;
  final String summary;
  final int? overallWinnerIndex;

  const AiComparisonResult({
    required this.colleges,
    required this.rows,
    required this.summary,
    this.overallWinnerIndex,
  });
}
