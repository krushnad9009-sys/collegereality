import '../../../core/constants/compare_constants.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../models/college_comparison_result.dart';

/// Full side-by-side comparison using verified Firestore data only.
class CollegeComparisonService {
  CollegeComparisonResult compare(List<CollegeModel> colleges) {
    final limited = colleges.take(CompareConstants.maxColleges).toList();
    if (limited.isEmpty) {
      return const CollegeComparisonResult(
        colleges: [],
        rows: [],
        summary: 'No colleges to compare.',
      );
    }
    if (limited.length < CompareConstants.minCollegesToCompare) {
      return CollegeComparisonResult(
        colleges: limited,
        rows: const [],
        summary:
            'Add at least ${CompareConstants.minCollegesToCompare} colleges to compare (max ${CompareConstants.maxColleges}).',
      );
    }

    final rows = <ComparisonRow>[
      _scoreRow('CR Score', 'CR Score', limited, (c) => CrScoreEngine.effectiveScore(c)),
      _ratingRow('Overall Rating', 'Ratings', limited, (c) => c.aggregatedRatings.overall),
      _ratingRow('Teaching', 'Ratings', limited, (c) => c.aggregatedRatings.teaching),
      _ratingRow('Placement', 'Ratings', limited, (c) => c.aggregatedRatings.placements),
      _ratingRow('Faculty', 'Ratings', limited, (c) => c.aggregatedRatings.faculty),
      _ratingRow('Labs', 'Ratings', limited, (c) => c.aggregatedRatings.labs),
      _ratingRow('Library', 'Ratings', limited, (c) => c.aggregatedRatings.library),
      _ratingRow('Hostel', 'Ratings', limited, (c) => c.aggregatedRatings.hostel),
      _ratingRow('Food', 'Ratings', limited, (c) => c.aggregatedRatings.food),
      _ratingRow('Infrastructure', 'Ratings', limited, (c) => c.aggregatedRatings.infrastructure),
      _ratingRow('Safety', 'Ratings', limited, (c) => c.aggregatedRatings.safety),
      _textRow(
        'Fees (Annual)',
        'Fees & Career',
        limited,
        (c) => _feeLabel(c),
        higherIsBetter: false,
        numeric: _averageFee,
      ),
      _textRow(
        'Average Package',
        'Fees & Career',
        limited,
        (c) => c.placements.averagePackageLpa > 0
            ? '${c.placements.averagePackageLpa.toStringAsFixed(1)} LPA'
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.averagePackageLpa,
      ),
      _textRow(
        'Highest Package',
        'Fees & Career',
        limited,
        (c) => c.placements.highestPackageLpa > 0
            ? '${c.placements.highestPackageLpa.toStringAsFixed(1)} LPA'
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.highestPackageLpa,
      ),
      _textRow(
        'Accreditation',
        'Accreditation',
        limited,
        _accreditationLabel,
      ),
      _textRow(
        'Courses',
        'Academics',
        limited,
        (c) {
          final courses = c.displayCourses;
          if (courses.isEmpty) return '—';
          if (courses.length <= 3) return courses.join(', ');
          return '${courses.take(3).join(', ')} +${courses.length - 3} more';
        },
      ),
      _textRow(
        'Verified Reviews',
        'Trust',
        limited,
        (c) => c.reviewCount.toString(),
        higherIsBetter: true,
        numeric: (c) => c.reviewCount.toDouble(),
      ),
    ];

    final insights = _buildInsights(limited, rows);
    final winnerIndex = _bestIndex(
      limited.map((c) => CrScoreEngine.effectiveScore(c)).toList(),
      higherIsBetter: true,
    );
    final summary = _buildSummary(limited, winnerIndex);

    return CollegeComparisonResult(
      colleges: limited,
      rows: rows,
      insights: insights,
      summary: summary,
      overallWinnerIndex: winnerIndex,
    );
  }

  List<CollegeCompareInsight> _buildInsights(
    List<CollegeModel> colleges,
    List<ComparisonRow> rows,
  ) {
    return colleges.map((college) {
      final idx = colleges.indexOf(college);
      final strengths = <String>[];
      final weaknesses = <String>[];

      for (final row in rows) {
        if (row.winnerIndex == null || row.values[idx] == '—') continue;
        final label = row.metric;
        if (row.winnerIndex == idx) {
          strengths.add('$label: ${row.values[idx]} (best among compared)');
        } else if (row.higherIsBetter) {
          final allNumeric = row.values.every((v) => v != '—');
          if (allNumeric && row.winnerIndex != idx) {
            final isLowest = _isLowestAmong(row, idx);
            if (isLowest) {
              weaknesses.add('$label: ${row.values[idx]} (lowest among compared)');
            }
          }
        } else {
          final isHighest = _isHighestAmong(row, idx);
          if (isHighest && row.winnerIndex != idx) {
            weaknesses.add('$label: ${row.values[idx]} (highest among compared)');
          }
        }
      }

      if (college.reviewCount == 0) {
        weaknesses.add('No verified student reviews yet in Firestore.');
      } else if (college.reviewCount >= 10) {
        strengths.add(
          '${college.reviewCount} verified reviews — strong data confidence.',
        );
      }

      return CollegeCompareInsight(
        collegeId: college.id,
        collegeName: college.name,
        strengths: strengths.take(5).toList(),
        weaknesses: weaknesses.take(4).toList(),
      );
    }).toList();
  }

  bool _isLowestAmong(ComparisonRow row, int index) {
    final values = row.values;
    final target = values[index];
    return values.where((v) => v != '—').every((v) {
      if (v == target) return true;
      return _parseNumeric(v) >= _parseNumeric(target);
    });
  }

  bool _isHighestAmong(ComparisonRow row, int index) {
    final values = row.values;
    final target = values[index];
    return values.where((v) => v != '—').every((v) {
      if (v == target) return true;
      return _parseNumeric(v) <= _parseNumeric(target);
    });
  }

  double _parseNumeric(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  ComparisonRow _scoreRow(
    String metric,
    String category,
    List<CollegeModel> colleges,
    double Function(CollegeModel) getter,
  ) {
    final values = colleges.map((c) {
      final v = getter(c);
      return v > 0 ? '${v.toStringAsFixed(0)}/100' : '—';
    }).toList();

    var winnerIndex = _bestIndex(
      colleges.map(getter).toList(),
      higherIsBetter: true,
    );
    if (colleges.every((c) => getter(c) <= 0)) winnerIndex = null;

    return ComparisonRow(
      metric: metric,
      category: category,
      values: values,
      winnerIndex: winnerIndex,
      higherIsBetter: true,
    );
  }

  ComparisonRow _ratingRow(
    String metric,
    String category,
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

    return ComparisonRow(
      metric: metric,
      category: category,
      values: values,
      winnerIndex: winnerIndex,
      higherIsBetter: true,
    );
  }

  ComparisonRow _textRow(
    String metric,
    String category,
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
      if (colleges.every((c) => numeric(c) <= 0)) winnerIndex = null;
    }
    return ComparisonRow(
      metric: metric,
      category: category,
      values: values,
      winnerIndex: winnerIndex,
      higherIsBetter: higherIsBetter,
    );
  }

  int? _bestIndex(List<double> values, {required bool higherIsBetter}) {
    if (values.isEmpty) return null;
    int? best;
    for (var i = 0; i < values.length; i++) {
      final current = values[i];
      if (current <= 0 || current.isInfinite || current.isNaN) continue;
      if (best == null) {
        best = i;
        continue;
      }
      final bestVal = values[best];
      if (higherIsBetter) {
        if (current > bestVal) best = i;
      } else {
        if (current < bestVal) best = i;
      }
    }
    return best;
  }

  String _buildSummary(List<CollegeModel> colleges, int? winnerIndex) {
    if (winnerIndex == null || winnerIndex >= colleges.length) {
      return 'Side-by-side comparison using verified college records. '
          'Missing fields are shown as —.';
    }
    final winner = colleges[winnerIndex];
    return '${winner.name} leads on CR Score '
        '(${CrScoreEngine.effectiveScore(winner).toStringAsFixed(0)}/100, '
        '${winner.reviewCount} verified reviews). All statistics are from Firestore — '
        'nothing is generated or estimated.';
  }

  static String _feeLabel(CollegeModel c) {
    return IndianCurrencyFormatter.formatRange(
      min: c.fees.tuitionMin,
      max: c.fees.tuitionMax,
    );
  }

  static double _averageFee(CollegeModel c) {
    final min = c.fees.tuitionMin;
    final max = c.fees.tuitionMax;
    if (min > 0 && max > 0) return (min + max) / 2;
    return (max > 0 ? max : min).toDouble();
  }

  static String _accreditationLabel(CollegeModel c) {
    final parts = <String>[];
    final acc = c.accreditation;
    if (acc.naacGrade != null && acc.naacGrade!.isNotEmpty) {
      parts.add('NAAC ${acc.naacGrade}');
    }
    if (acc.nirfRank != null) parts.add('NIRF #${acc.nirfRank}');
    if (acc.ugcRecognized) parts.add('UGC');
    if (acc.aicteApproved) parts.add('AICTE');
    return parts.isEmpty ? '—' : parts.join(' • ');
  }
}
