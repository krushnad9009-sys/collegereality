import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../../colleges/models/college_model.dart';
import '../models/cr_score_model.dart';
import '../utils/cr_score_engine.dart';
import 'cr_score_category_bars.dart';
import 'cr_score_gauge_widget.dart';

class CrScoreCardWidget extends StatelessWidget {
  final CollegeModel college;
  final bool compact;

  const CrScoreCardWidget({
    required this.college,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = college.crScore > 0
        ? CrScoreSnapshot.fromCollege(college)
        : CrScoreEngine.compute(college);
    final color = CrScoreConstants.colorForScore(snapshot.score);
    final updatedLabel = _updatedLabel(snapshot.updatedAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              AppTheme.white,
            ],
          ),
        ),
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CR Score',
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push(RouteNames.howCrScoreWorks),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('How it works'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CrScoreGaugeWidget(
                  score: snapshot.score,
                  size: compact ? 110 : 132,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Grade',
                        value: snapshot.score > 0 ? snapshot.grade : '—',
                        valueColor: color,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Confidence',
                        value: snapshot.confidenceLabel,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Based on',
                        value: snapshot.verifiedReviewCount > 0
                            ? '${NumberFormat.decimalPattern().format(snapshot.verifiedReviewCount)} Verified Reviews'
                            : 'No verified reviews yet',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Last Updated',
                        value: updatedLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 20),
              Text(
                'Category Scores',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              CrScoreCategoryBars(categories: snapshot.categories),
            ],
          ],
        ),
      ),
    );
  }

  String _updatedLabel(DateTime? updatedAt) {
    if (updatedAt == null) return 'Live';
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 5) return 'Live';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, yyyy').format(updatedAt);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.gray800,
          ),
        ),
      ],
    );
  }
}
