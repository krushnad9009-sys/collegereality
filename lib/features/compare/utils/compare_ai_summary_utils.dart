import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../models/college_comparison_result.dart';
import '../services/college_comparison_service.dart';

class CompareAiSummaryUtils {
  CompareAiSummaryUtils._();

  static CompareAiSummary build(List<CollegeModel> colleges) {
    if (colleges.length < 2) return const CompareAiSummary();

    final placementIdx = _bestIndex(
      colleges,
      (c) => CrScoreEngine.compute(c).categories.placements,
    );
    final campusIdx = _bestIndex(
      colleges,
      (c) => CrScoreEngine.compute(c).categories.campusLife,
    );
    final valueIdx = _bestIndex(
      colleges,
      (c) => _valueScore(c),
    );
    final overallIdx = _bestIndex(
      colleges,
      (c) => CrScoreEngine.effectiveScore(c),
    );

    return CompareAiSummary(
      bestForPlacements: placementIdx != null
          ? colleges[placementIdx].name
          : null,
      bestForCampusLife:
          campusIdx != null ? colleges[campusIdx].name : null,
      bestValueForMoney: valueIdx != null ? colleges[valueIdx].name : null,
      bestOverall: overallIdx != null ? colleges[overallIdx].name : null,
    );
  }

  static double _valueScore(CollegeModel college) {
    final cr = CrScoreEngine.effectiveScore(college);
    final fee = CollegeComparisonService.averageAnnualFee(college);
    if (cr <= 0 || fee <= 0) return 0;
    return cr / (fee / 100000);
  }

  static int? _bestIndex(
    List<CollegeModel> colleges,
    double Function(CollegeModel) getter,
  ) {
    int? best;
    for (var i = 0; i < colleges.length; i++) {
      final value = getter(colleges[i]);
      if (value <= 0) continue;
      if (best == null || value > getter(colleges[best])) {
        best = i;
      }
    }
    return best;
  }
}
