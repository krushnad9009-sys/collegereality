import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final double starSize;
  final bool readOnly;

  const StarRatingWidget({
    required this.rating,
    this.onRatingChanged,
    this.starSize = 28,
    this.readOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isFilled = rating >= starValue;
        final isHalf = !isFilled && rating >= starValue - 0.5;

        return GestureDetector(
          onTap: readOnly || onRatingChanged == null
              ? null
              : () => onRatingChanged!(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled
                  ? Icons.star_rounded
                  : isHalf
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              color: AppTheme.warningColor,
              size: starSize,
            ),
          ),
        );
      }),
    );
  }
}

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;

  const StarRatingDisplay({
    required this.rating,
    this.reviewCount,
    this.starSize = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRatingWidget(rating: rating, starSize: starSize, readOnly: true),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: starSize * 0.85,
            color: tokens.textPrimary,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: AppFonts.plusJakarta(
              fontSize: starSize * 0.75,
              color: tokens.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingInputRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const RatingInputRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value > 0;
    final sliderValue = hasValue ? value : 3.0;
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasValue ? '${value.toStringAsFixed(0)}/5' : 'Tap slider',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: tokens.borderSubtle,
              thumbColor: primary,
              overlayColor: primary.withValues(alpha: 0.12),
              trackHeight: 6,
            ),
            child: Slider(
              value: sliderValue,
              min: 1,
              max: 5,
              divisions: 4,
              label: sliderValue.toStringAsFixed(0),
              onChanged: enabled ? (v) => onChanged(v.roundToDouble()) : null,
            ),
          ),
        ],
      ),
    );
  }
}
