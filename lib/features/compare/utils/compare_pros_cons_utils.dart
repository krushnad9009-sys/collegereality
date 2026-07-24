import '../../../core/constants/compare_constants.dart';
import '../../reviews/models/review_model.dart';
import '../models/college_comparison_result.dart';

/// Aggregates verified review pros and cons for comparison cards.
class CompareProsConsUtils {
  CompareProsConsUtils._();

  static CollegeProsCons buildForCollege({
    required String collegeId,
    required String collegeName,
    required List<ReviewModel> reviews,
  }) {
    final public = reviews.where((r) => r.isPublicVisible).toList();
    return CollegeProsCons(
      collegeId: collegeId,
      collegeName: collegeName,
      pros: _topItems(public.expand((r) => r.pros)),
      cons: _topItems(public.expand((r) => r.cons)),
    );
  }

  static List<String> _topItems(Iterable<String> items) {
    final counts = <String, int>{};
    for (final raw in items) {
      final item = raw.trim();
      if (item.isEmpty) continue;
      final key = item.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(CompareConstants.maxProsConsItems)
        .map((e) => _titleCase(e.key))
        .toList();
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
