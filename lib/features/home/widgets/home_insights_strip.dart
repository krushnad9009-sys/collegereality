import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/college_constants.dart';
import '../../colleges/providers/college_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../providers/home_content_provider.dart';

/// Data-driven CR Score / placement insights band. Every figure is computed
/// from the same real, already-fetched provider data the rest of the page
/// uses ([topRatedCollegesProvider], [homePlacementHighlightsProvider],
/// [collegeCountProvider]) — nothing here is invented. Metrics that can't
/// be computed from real data fall back to a "—" placeholder rather than a
/// made-up number.
class HomeInsightsStrip extends ConsumerWidget {
  const HomeInsightsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final topRated = ref.watch(topRatedCollegesProvider).valueOrNull;
    final placements = ref.watch(homePlacementHighlightsProvider).valueOrNull;
    final collegeCount = ref.watch(collegeCountProvider).valueOrNull;

    final topCrScore = (topRated != null && topRated.isNotEmpty)
        ? topRated.map(CrScoreEngine.effectiveScore).reduce((a, b) => a > b ? a : b)
        : null;
    final bestPackage = (placements != null && placements.isNotEmpty)
        ? placements.map((c) => c.placements.averagePackageLpa).reduce((a, b) => a > b ? a : b)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CR Score & placement insights',
                  style: AppFonts.plusJakarta(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(RouteNames.rankingInsights),
                child: Text(
                  'See rankings',
                  style: AppFonts.plusJakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InsightMetric(
                  icon: Icons.school_rounded,
                  color: const Color(0xFF0F766E),
                  value: collegeCount != null && collegeCount > 0
                      ? '${CollegeConstants.formatCollegeCount(collegeCount)}+'
                      : '${CollegeConstants.formatCollegeCount(CollegeConstants.auditedProductionCount)}+',
                  label: 'Colleges tracked',
                ),
              ),
              _Divider(color: tokens.borderSubtle),
              Expanded(
                child: _InsightMetric(
                  icon: Icons.insights_rounded,
                  color: const Color(0xFF0369A1),
                  value: topCrScore != null && topCrScore > 0 ? topCrScore.toStringAsFixed(0) : '—',
                  label: 'Top CR Score',
                ),
              ),
              _Divider(color: tokens.borderSubtle),
              Expanded(
                child: _InsightMetric(
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF059669),
                  value: bestPackage != null && bestPackage > 0 ? '₹${bestPackage.toStringAsFixed(1)}L' : '—',
                  label: 'Best package',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;

  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: color);
}

class _InsightMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _InsightMetric({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppFonts.plusJakarta(fontSize: 16, fontWeight: FontWeight.w800, color: tokens.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.plusJakarta(fontSize: 10.5, fontWeight: FontWeight.w500, color: tokens.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
