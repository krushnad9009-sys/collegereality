import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';

class VerificationBadgeWidget extends StatelessWidget {
  final String badge;
  final double iconSize;

  const VerificationBadgeWidget({
    required this.badge,
    this.iconSize = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (badge == VerificationConstants.badgeNone) {
      return const SizedBox.shrink();
    }

    final isAlumni = badge == VerificationConstants.badgeVerifiedAlumni;
    final color =
        isAlumni ? const Color(0xFF7C3AED) : AppTheme.accentColor;
    final label = VerificationConstants.badgeLabel(badge);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
