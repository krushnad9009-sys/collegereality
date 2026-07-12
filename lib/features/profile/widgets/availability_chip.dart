import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/profile_constants.dart';

class AvailabilityChip extends StatelessWidget {
  final String status;

  const AvailabilityChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ProfileConstants.availabilityAvailable:
        color = AppTheme.accentColor;
        icon = Icons.circle;
        label = 'Available';
        break;
      case ProfileConstants.availabilityBusy:
        color = AppTheme.warningColor;
        icon = Icons.do_not_disturb_on;
        label = 'Busy';
        break;
      default:
        color = AppTheme.gray500;
        icon = Icons.circle_outlined;
        label = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
