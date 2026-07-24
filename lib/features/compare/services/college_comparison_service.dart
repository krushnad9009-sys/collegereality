import '../../../core/constants/compare_constants.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../reviews/models/review_model.dart';
import '../models/college_comparison_result.dart';
import '../utils/compare_ai_summary_utils.dart';
import '../utils/compare_pros_cons_utils.dart';

/// Full side-by-side comparison using verified Firestore data only.
class CollegeComparisonService {
  CollegeComparisonResult compare(
    List<CollegeModel> colleges, {
    Map<String, List<ReviewModel>> reviewsByCollege = const {},
  }) {
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
      _scoreRow('CR Score', 'CR Score', limited, CrScoreEngine.effectiveScore),
      _textRow(
        'Grade',
        'CR Score',
        limited,
        (c) {
          final score = CrScoreEngine.effectiveScore(c);
          return score > 0 ? CrScoreConstants.gradeForScore(score) : '—';
        },
      ),
      _textRow(
        'Confidence Level',
        'CR Score',
        limited,
        (c) => CrScoreConstants.confidenceLabel(c.reviewCount),
      ),
      _textRow(
        'Total Verified Reviews',
        'CR Score',
        limited,
        (c) => c.reviewCount.toString(),
        higherIsBetter: true,
        numeric: (c) => c.reviewCount.toDouble(),
      ),
      _textRow(
        'Fees',
        'Fees & Placements',
        limited,
        _feeLabel,
        higherIsBetter: false,
        numeric: averageAnnualFee,
      ),
      _textRow(
        'Average Package',
        'Fees & Placements',
        limited,
        (c) => c.placements.averagePackageLpa > 0
            ? '${c.placements.averagePackageLpa.toStringAsFixed(1)} LPA'
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.averagePackageLpa,
      ),
      _textRow(
        'Highest Package',
        'Fees & Placements',
        limited,
        (c) => c.placements.highestPackageLpa > 0
            ? '${c.placements.highestPackageLpa.toStringAsFixed(1)} LPA'
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.highestPackageLpa,
      ),
      _textRow(
        'Placement Rate',
        'Fees & Placements',
        limited,
        (c) => c.placements.placementPercentage > 0
            ? '${c.placements.placementPercentage.toStringAsFixed(0)}%'
            : '—',
        higherIsBetter: true,
        numeric: (c) => c.placements.placementPercentage.toDouble(),
      ),
      _scoreRow(
        'Education Quality',
        'Category Scores',
        limited,
        (c) => CrScoreEngine.compute(c).categories.education,
      ),
      _scoreRow(
        'Campus Life',
        'Category Scores',
        limited,
        (c) => CrScoreEngine.compute(c).categories.campusLife,
      ),
      _scoreRow(
        'Infrastructure',
        'Category Scores',
        limited,
        (c) => CrScoreEngine.compute(c).categories.infrastructure,
      ),
      _scoreRow(
        'Safety & Discipline',
        'Category Scores',
        limited,
        (c) => CrScoreEngine.compute(c).categories.safety,
      ),
      _ratingRow('Hostel', 'Student Life', limited, (c) => c.aggregatedRatings.hostel),
      _ratingRow('Faculty', 'Student Life', limited, (c) => c.aggregatedRatings.faculty),
      _textRow(
        'Location',
        'College Info',
        limited,
        (c) => c.locationLabel,
      ),
      _textRow(
        'Courses Offered',
        'College Info',
        limited,
        (c) {
          final courses = c.displayCourses;
          if (courses.isEmpty) return '—';
          if (courses.length <= 4) return courses.join(', ');
          return '${courses.take(4).join(', ')} +${courses.length - 4} more';
        },
      ),
      _textRow(
        'NAAC Grade',
        'Accreditation',
        limited,
        (c) {
          final grade = c.accreditation.naacGrade;
          return grade != null && grade.isNotEmpty ? grade : '—';
        },
      ),
      _textRow(
        'NIRF Rank',
        'Accreditation',
        limited,
        (c) {
          final rank = c.accreditation.nirfRank;
          return rank != null && rank > 0 ? '#$rank' : '—';
        },
        higherIsBetter: false,
        numeric: (c) {
          final rank = c.accreditation.nirfRank;
          if (rank == null || rank <= 0) return 0;
          return rank.toDouble();
        },
      ),
    ];

    final prosCons = limited
        .map(
          (college) => CompareProsConsUtils.buildForCollege(
            collegeId: college.id,
            collegeName: college.name,
            reviews: reviewsByCollege[college.id] ?? const [],
          ),
        )
        .toList();

    final insights = _buildInsights(limited, rows);
    final aiSummary = CompareAiSummaryUtils.build(limited);
    final winnerIndex = _bestIndex(
      limited.map(CrScoreEngine.effectiveScore).toList(),
      higherIsBetter: true,
    );
    final summary = _buildSummary(limited, winnerIndex);

    return CollegeComparisonResult(
      colleges: limited,
      rows: rows,
      insights: insights,
      prosCons: prosCons,
      aiSummary: aiSummary,
      summary: summary,
      overallWinnerIndex: winnerIndex,
    );
  }

  List<CollegeCompareInsight> _buildInsights(
    List<CollegeModel> colleges,
    List<ComparisonRow> rows,
  ) {
    return colleges.asMap().entries.map((entry) {
      final idx = entry.key;
      final college = entry.value;
      final strengths = <String>[];
      final weaknesses = <String>[];

      for (final row in rows) {
        if (row.winnerIndex == null || row.values[idx] == '—') continue;
        final label = row.metric;
        if (row.winnerIndex == idx) {
          strengths.add('$label: ${row.values[idx]} (best among compared)');
        } else if (row.higherIsBetter) {
          if (_isLowestAmong(row, idx)) {
            weaknesses.add('$label: ${row.values[idx]} (lowest among compared)');
          }
        } else if (_isHighestAmong(row, idx) && row.winnerIndex != idx) {
          weaknesses.add('$label: ${row.values[idx]} (highest among compared)');
        }
      }

      if (college.reviewCount == 0) {
        weaknesses.add('No verified student reviews yet.');
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
    final target = row.values[index];
    return row.values.where((v) => v != '—').every((v) {
      if (v == target) return true;
      return _parseNumeric(v) >= _parseNumeric(target);
    });
  }

  bool _isHighestAmong(ComparisonRow row, int index) {
    final target = row.values[index];
    return row.values.where((v) => v != '—').every((v) {
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
      return 'Side-by-side comparison using verified student feedback only. '
          'Missing fields are shown as —.';
    }
    final winner = colleges[winnerIndex];
    return '${winner.name} is the overall winner based on CR Score '
        '(${CrScoreEngine.effectiveScore(winner).toStringAsFixed(0)}/100, '
        '${winner.reviewCount} verified reviews).';
  }

  static String _feeLabel(CollegeModel c) {
    return IndianCurrencyFormatter.formatRange(
      min: c.fees.tuitionMin,
      max: c.fees.tuitionMax,
    );
  }

  static double averageAnnualFee(CollegeModel c) {
    final min = c.fees.tuitionMin;
    final max = c.fees.tuitionMax;
    if (min > 0 && max > 0) return (min + max) / 2;
    return (max > 0 ? max : min).toDouble();
  }
}
