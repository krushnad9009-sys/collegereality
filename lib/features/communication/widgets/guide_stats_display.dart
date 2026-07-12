import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/guide_stats_model.dart';
import '../utils/communication_formatters.dart';
import 'guide_badge_widget.dart';

class GuideStatsDisplay extends StatelessWidget {
  final GuideStatsModel stats;
  final bool showVerified;
  final bool isVerified;

  const GuideStatsDisplay({
    required this.stats,
    this.showVerified = true,
    this.isVerified = false,
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
            if (showVerified && isVerified)
              _Chip(
                icon: Icons.verified,
                label: 'Verified',
                color: AppTheme.accentColor,
              ),
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
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
