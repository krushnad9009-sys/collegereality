import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../ranking/widgets/cr_score_badge_widget.dart';

class CompareWinnerBanner extends StatelessWidget {
  final CollegeModel college;

  const CompareWinnerBanner({required this.college, super.key});

  @override
  Widget build(BuildContext context) {
    final score = CrScoreEngine.effectiveScore(college);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.accentColor.withValues(alpha: 0.18),
              AppTheme.primaryColor.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Winner',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  Text(
                    college.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Best CR Score among compared colleges',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            CrScoreBadgeWidget(score: score, showGrade: true),
          ],
        ),
      ),
    );
  }
}
