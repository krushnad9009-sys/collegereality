import 'package:intl/intl.dart';

import '../../colleges/models/college_model.dart';
import '../models/ai_comparison_result.dart';

/// Side-by-side comparison using verified college data only.
class AiComparisonService {
  static final _currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  AiComparisonResult compare(
    List<CollegeModel> colleges, {
    String? focusMetric,
  }) {
    final limited = colleges.take(5).toList();
    if (limited.isEmpty) {
      return const AiComparisonResult(
        colleges: [],
        rows: [],
        summary: 'No colleges to compare.',
      );
    }
    if (limited.length == 1) {
      return AiComparisonResult(
        colleges: limited,
        rows: const [],
        summary:
            'Only one college in context. Add more colleges to compare (up to 5).',
      );
    }

    final rows = <AiComparisonRow>[
      _ratingRow('Overall Rating', limited, (c) => c.aggregatedRatings.overall),
      _ratingRow('Placements Rating', limited, (c) => c.aggregatedRatings.placements),
      _textRow(
        'Placement %',
        limited,
        (c) => c.placements.placementPercentage > 0
            ? '${c.placements.placementPercentage}%'
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.placementPercentage.toDouble(),
      ),
      _textRow(
        'Avg Package (LPA)',
        limited,
        (c) => c.placements.averagePackageLpa > 0
            ? c.placements.averagePackageLpa.toStringAsFixed(1)
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.averagePackageLpa,
      ),
      _textRow(
        'Annual Fees',
        limited,
        (c) {
          final min = c.fees.tuitionMin;
          final max = c.fees.tuitionMax;
          if (min <= 0 && max <= 0) return '—';
          if (min > 0 && max > 0) {
            return '${_currency.format(min)} – ${_currency.format(max)}';
          }
          return _currency.format(max > 0 ? max : min);
        },
        higherIsBetter: false,
        numeric: (c) {
          final min = c.fees.tuitionMin;
          final max = c.fees.tuitionMax;
          if (min > 0 && max > 0) return (min + max) / 2;
          return (max > 0 ? max : min).toDouble();
        },
      ),
      _ratingRow('Faculty Rating', limited, (c) => c.aggregatedRatings.faculty),
      _ratingRow('Hostel Rating', limited, (c) => c.aggregatedRatings.hostel),
      _textRow(
        'Hostel Available',
        limited,
        (c) => c.hostel.available ? 'Yes' : 'No',
      ),
      _textRow(
        'NAAC Grade',
        limited,
        (c) => c.accreditation.naacGrade ?? '—',
      ),
      _textRow(
        'NIRF Rank',
        limited,
        (c) => c.accreditation.nirfRank?.toString() ?? '—',
        higherIsBetter: false,
        numeric: (c) => c.accreditation.nirfRank?.toDouble() ?? double.infinity,
      ),
      _textRow(
        'Verified Reviews',
        limited,
        (c) => c.reviewCount.toString(),
        higherIsBetter: true,
        numeric: (c) => c.reviewCount.toDouble(),
      ),
      _textRow(
        'Location',
        limited,
        (c) => c.locationLabel,
      ),
    ];

    final winnerIndex = _overallWinner(limited, focusMetric);
    final summary = _buildSummary(limited, winnerIndex, focusMetric);

    return AiComparisonResult(
      colleges: limited,
      rows: rows,
      summary: summary,
      overallWinnerIndex: winnerIndex,
    );
  }

  AiComparisonRow _ratingRow(
    String metric,
    List<CollegeModel> colleges,
    double Function(CollegeModel) getter,
  ) {
    final values = colleges.map((c) {
      final v = getter(c);
      return v > 0 ? '${v.toStringAsFixed(1)}/5' : '—';
    }).toList();

    var winnerIndex = _bestIndex(
      colleges.map(getter).toList(),
      higherIsBetter: true,
    );

    if (colleges.every((c) => getter(c) <= 0)) winnerIndex = null;

    return AiComparisonRow(
      metric: metric,
      values: values,
      winnerIndex: winnerIndex,
    );
  }

  AiComparisonRow _textRow(
    String metric,
    List<CollegeModel> colleges,
    String Function(CollegeModel) formatter, {
    bool higherIsBetter = true,
    double Function(CollegeModel)? numeric,
  }) {
    final values = colleges.map(formatter).toList();
    int? winnerIndex;
    if (numeric != null) {
      winnerIndex = _bestIndex(
        colleges.map(numeric).toList(),
        higherIsBetter: higherIsBetter,
      );
    }
    return AiComparisonRow(
      metric: metric,
      values: values,
      winnerIndex: winnerIndex,
    );
  }

  int? _bestIndex(List<double> values, {required bool higherIsBetter}) {
    if (values.isEmpty) return null;
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      final current = values[i];
      final bestVal = values[best];
      if (current.isInfinite || current.isNaN) continue;
      if (bestVal.isInfinite || bestVal.isNaN) {
        best = i;
        continue;
      }
      if (higherIsBetter) {
        if (current > bestVal) best = i;
      } else {
        if (current < bestVal) best = i;
      }
    }
    return best;
  }

  int? _overallWinner(List<CollegeModel> colleges, String? focusMetric) {
    switch (focusMetric) {
      case 'placements':
        return _bestIndex(
          colleges.map((c) => c.aggregatedRatings.placements).toList(),
          higherIsBetter: true,
        );
      case 'fees':
        return _bestIndex(
          colleges.map((c) {
            final min = c.fees.tuitionMin;
            final max = c.fees.tuitionMax;
            if (min > 0 && max > 0) return (min + max) / 2;
            return (max > 0 ? max : min).toDouble();
          }).toList(),
          higherIsBetter: false,
        );
      case 'faculty':
        return _bestIndex(
          colleges.map((c) => c.aggregatedRatings.faculty).toList(),
          higherIsBetter: true,
        );
      case 'hostel':
        return _bestIndex(
          colleges.map((c) => c.aggregatedRatings.hostel).toList(),
          higherIsBetter: true,
        );
      default:
        return _bestIndex(
          colleges.map((c) => c.aggregatedRatings.overall).toList(),
          higherIsBetter: true,
        );
    }
  }

  String _buildSummary(
    List<CollegeModel> colleges,
    int? winnerIndex,
    String? focusMetric,
  ) {
    if (winnerIndex == null || winnerIndex >= colleges.length) {
      return 'Comparison based on verified Firestore data. '
          'Some fields may be unavailable for certain colleges.';
    }
    final winner = colleges[winnerIndex];
    final metricLabel = switch (focusMetric) {
      'placements' => 'placements',
      'fees' => 'fees',
      'faculty' => 'faculty',
      'hostel' => 'hostel',
      _ => 'overall rating',
    };
    return 'Based on verified data, ${winner.name} leads on $metricLabel '
        'among the compared colleges. All figures are from our Firestore database.';
  }
}
