import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/review_page_model.dart';

class RatingDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const RatingDistributionChart({required this.distribution, super.key});

  @override
  Widget build(BuildContext context) {
    final parsed = RatingDistribution.fromJson(distribution);
    final total = parsed.total;

    if (total == 0) {
      return Text(
        'No ratings yet',
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
      );
    }

    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = parsed.countFor(stars);
        final fraction = parsed.fractionFor(stars);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$stars★',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: AppTheme.gray200,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
