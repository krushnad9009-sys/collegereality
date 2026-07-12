import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/communication_constants.dart';

class GuideBadgeWidget extends StatelessWidget {
  final String badgeTier;
  final double size;

  const GuideBadgeWidget({
    required this.badgeTier,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeTier == 'none') return const SizedBox.shrink();

    Color color;
    String label;
    IconData icon;

    switch (badgeTier) {
      case CommunicationConstants.subscriptionGold:
        color = const Color(0xFFFFD700);
        label = 'Gold Guide';
        icon = Icons.workspace_premium;
        break;
      case CommunicationConstants.subscriptionSilver:
        color = const Color(0xFFC0C0C0);
        label = 'Silver Guide';
        icon = Icons.military_tech;
        break;
      case CommunicationConstants.subscriptionBronze:
        color = const Color(0xFFCD7F32);
        label = 'Bronze Guide';
        icon = Icons.emoji_events_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.gray800,
            ),
          ),
        ],
      ),
    );
  }
}
