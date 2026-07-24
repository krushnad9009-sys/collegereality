import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';

class CrScoreBadgeWidget extends StatelessWidget {
  final double score;
  final bool showGrade;
  final double fontSize;

  const CrScoreBadgeWidget({
    required this.score,
    this.showGrade = false,
    this.fontSize = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (score <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No CR Score',
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.gray500,
          ),
        ),
      );
    }

    final color = CrScoreConstants.colorForScore(score);
    final grade = CrScoreConstants.gradeForScore(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            showGrade ? '${score.toStringAsFixed(0)} · $grade' : score.toStringAsFixed(0),
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
