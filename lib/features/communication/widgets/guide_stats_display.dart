import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
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
    final tokens = context.tokens;
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
              icon: Icons.star_rounded,
            ),
            const SizedBox(width: 8),
            _StatBox(
              label: 'Chats',
              value: '${stats.totalChats}',
              icon: Icons.chat_bubble_outline_rounded,
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
          style: AppFonts.plusJakarta(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatLastActive(stats.lastActiveAt),
          style: AppFonts.plusJakarta(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.textSecondary,
          ),
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
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppFonts.plusJakarta(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: tokens.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
