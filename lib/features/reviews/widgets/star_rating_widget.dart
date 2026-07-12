import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRatingWidget(rating: rating, starSize: starSize, readOnly: true),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: starSize * 0.85,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: GoogleFonts.poppins(
              fontSize: starSize * 0.75,
              color: AppTheme.gray500,
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

  const RatingInputRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: StarRatingWidget(
              rating: value,
              onRatingChanged: onChanged,
              starSize: 24,
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              value > 0 ? value.toStringAsFixed(0) : '-',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
