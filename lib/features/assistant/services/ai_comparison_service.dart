import '../../colleges/models/college_model.dart';
import '../../compare/services/college_comparison_service.dart';
import '../models/ai_comparison_result.dart';

/// Assistant-facing adapter over the shared comparison engine.
class AiComparisonService {
  final CollegeComparisonService _service = CollegeComparisonService();

  AiComparisonResult compare(
    List<CollegeModel> colleges, {
    String? focusMetric,
  }) {
    final result = _service.compare(colleges);
    return AiComparisonResult(
      colleges: result.colleges,
      rows: result.rows
          .map(
            (r) => AiComparisonRow(
              metric: r.metric,
              values: r.values,
              winnerIndex: r.winnerIndex,
            ),
          )
          .toList(),
      summary: result.summary,
      overallWinnerIndex: result.overallWinnerIndex,
    );
  }
}
