import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';
import '../models/cr_score_model.dart';

class CrScoreCategoryBars extends StatelessWidget {
  final CrScoreCategories categories;

  const CrScoreCategoryBars({required this.categories, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: CrScoreConstants.categoryKeys.map((key) {
        final score = categories.scoreFor(key);
        final color = CrScoreConstants.colorForScore(score);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CrScoreConstants.categoryLabel(key),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    score > 0 ? score.toStringAsFixed(0) : '—',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score > 0 ? score / 100 : 0,
                  minHeight: 8,
                  backgroundColor: AppTheme.gray100,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
