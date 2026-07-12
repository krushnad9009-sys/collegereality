import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../models/guide_stats_model.dart';
import '../utils/communication_formatters.dart';
import 'guide_badge_widget.dart';

class GuideStatsDisplay extends StatelessWidget {
  final GuideStatsModel stats;
  final String verificationBadge;

  const GuideStatsDisplay({
    required this.stats,
    this.verificationBadge = 'none',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VerificationBadgeWidget(badge: verificationBadge),
            GuideBadgeWidget(badgeTier: stats.badgeTier),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatBox(
              label: 'Rating',
              value: stats.totalRatings > 0
                  ? stats.overallRating.toStringAsFixed(1)
                  : 'New',
              icon: Icons.star,
            ),
            const SizedBox(width: 8),
            _StatBox(
              label: 'Chats',
              value: '${stats.totalChats}',
              icon: Icons.chat_bubble_outline,
            ),
            const SizedBox(width: 8),
            _StatBox(
              label: 'Calls',
              value: '${stats.totalCalls}',
              icon: Icons.call_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          formatGuideResponseTime(stats.avgResponseTimeMinutes),
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600),
        ),
        const SizedBox(height: 4),
        Text(
          formatLastActive(stats.lastActiveAt),
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray600),
            ),
          ],
        ),
      ),
    );
  }
}
