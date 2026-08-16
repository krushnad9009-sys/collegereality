import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/review_page_model.dart';

class RatingDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const RatingDistributionChart({required this.distribution, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final parsed = RatingDistribution.fromJson(distribution);
    final total = parsed.total;

    if (total == 0) {
      return Text(
        'No ratings yet',
        style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
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
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: tokens.borderSubtle,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textSecondary),
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
