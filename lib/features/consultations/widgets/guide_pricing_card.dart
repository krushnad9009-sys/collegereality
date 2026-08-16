import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/premium_components.dart';
import '../../communication/models/public_guide_profile.dart';
import 'availability_badge.dart';

/// The premium "Talk to this student" card on a guide's public profile —
/// verified badge, live availability, priced chat/call/video options, and
/// aggregate consultation rating. No PII, no reviewer identity — matches
/// what PublicGuideProfile itself already exposes.
class GuidePricingCard extends StatelessWidget {
  final PublicGuideProfile guide;

  const GuidePricingCard({required this.guide, super.key});

  @override
  Widget build(BuildContext context) {
    final settings = guide.settings;
    if (!settings.hasAnyConsultationPricing || !guide.isEligibleGuide) {
      return const SizedBox.shrink();
    }
    final stats = guide.stats;
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 18, color: primary),
              const SizedBox(width: 6),
              Text(
                'Talk to this student',
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              const Spacer(),
              AvailabilityBadge(presence: guide.presence),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (settings.chatAvailable && settings.chatPricePaise > 0)
                _PriceChip(
                  icon: '💬',
                  label:
                      'Chat ₹${(settings.chatPricePaise / 100).toStringAsFixed(0)} / ${settings.chatDurationMinutes} min',
                  onTap: () => context.push(
                    RouteNames.consultationCheckoutPath(guide.uid),
                  ),
                ),
              if (settings.callAvailable)
                for (final option in settings.callPricing)
                  if (option.pricePaise > 0)
                    _PriceChip(
                      icon: option.type == 'video' ? '📹' : '📞',
                      label:
                          '${option.type == 'video' ? 'Video' : 'Call'} ₹${(option.pricePaise / 100).toStringAsFixed(0)} / ${option.minutes} min',
                      onTap: () => context.push(
                        RouteNames.consultationCheckoutPath(guide.uid),
                      ),
                    ),
            ],
          ),
          if (stats.completedConsultations > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  '${stats.consultationRatingAvg.toStringAsFixed(1)}  (${stats.completedConsultations} consultation${stats.completedConsultations == 1 ? '' : 's'})',
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _PriceChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumChip(
      label: '$icon $label',
      onTap: onTap,
    );
  }
}
