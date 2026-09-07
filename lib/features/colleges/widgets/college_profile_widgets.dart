import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_elevation.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/premium_list_row.dart';
import '../../reviews/widgets/review_summary_panel.dart';
import '../../community_feed/providers/college_community_feed_provider.dart';
import '../models/college_model.dart';

/// At-a-glance college stats as a row of modern floating cards:
/// Rating · Reviews · Verified students · Avg package · Tuition fees.
/// Missing data renders an elegant "No data yet" placeholder rather than a
/// coloured box implying a real value.
class CollegeProfileStatsStrip extends StatelessWidget {
  final CollegeModel college;

  const CollegeProfileStatsStrip({required this.college, super.key});

  String _feeValue() {
    final fees = college.fees;
    final min = fees.tuitionMin;
    final max = fees.tuitionMax;
    if (min > 0 && max > 0 && min != max) {
      return '${IndianCurrencyFormatter.compact(min)}–'
          '${IndianCurrencyFormatter.compact(max)}';
    }
    final single = max > 0 ? max : min;
    return single > 0 ? IndianCurrencyFormatter.compact(single) : '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratings = college.aggregatedRatings;
    final placements = college.placements;

    final avg = placements.averagePackageLpa;
    final avgStr = avg > 0
        ? '${avg == avg.roundToDouble() ? avg.toStringAsFixed(0) : avg.toStringAsFixed(1)} LPA'
        : '';

    final items = <_StatItem>[
      _StatItem(
        icon: Icons.star_rounded,
        label: 'Rating',
        value: ratings.overall > 0 ? ratings.overall.toStringAsFixed(1) : '',
        color: AppTheme.warningColor,
      ),
      _StatItem(
        icon: Icons.rate_review_outlined,
        label: 'Reviews',
        value: college.reviewCount > 0 ? '${college.reviewCount}' : '',
        color: scheme.primary,
      ),
      _StatItem(
        icon: Icons.verified_outlined,
        label: 'Verified students',
        value: college.verifiedStudentCount > 0
            ? '${college.verifiedStudentCount}'
            : '',
        color: const Color(0xFF0891B2),
      ),
      _StatItem(
        icon: Icons.work_outline_rounded,
        label: 'Avg package',
        value: avgStr,
        color: const Color(0xFF059669),
      ),
      _StatItem(
        icon: Icons.payments_outlined,
        label: 'Tuition fees',
        value: _feeValue(),
        color: scheme.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final perRow = constraints.maxWidth >= 640 ? 3 : 2;
        final cardWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _StatFloatingCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatFloatingCard extends StatelessWidget {
  final _StatItem item;

  const _StatFloatingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final empty = item.value.isEmpty;
    final accent = empty ? tokens.textTertiary : item.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius * 0.7),
        border: Border.all(color: tokens.borderSubtle),
        boxShadow: isDark ? null : AppElevation.soft(AppTheme.primaryDark),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: empty ? 0.10 : 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  empty ? 'No data yet' : item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: empty ? 11.5 : 15,
                    fontWeight: empty ? FontWeight.w500 : FontWeight.w800,
                    letterSpacing: -0.2,
                    color: empty ? tokens.textTertiary : tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Key facts grid: city, state, ownership, type, established year.
class CollegeProfileFactsGrid extends StatelessWidget {
  final CollegeModel college;

  const CollegeProfileFactsGrid({required this.college, super.key});

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String, String)>[
      (Icons.location_city_outlined, 'City', college.city),
      (Icons.map_outlined, 'State', college.state),
      (Icons.account_balance_outlined, 'Ownership', college.ownershipLabel),
      (Icons.category_outlined, 'Type', college.type),
      if (college.establishedYear != null)
        (
          Icons.calendar_today_outlined,
          'Established',
          '${college.establishedYear}',
        ),
      if (college.category.isNotEmpty && college.category != 'General')
        (Icons.label_outline, 'Category', college.category),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: facts.map((fact) {
            return SizedBox(
              width: wide
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth,
              child: _FactTile(icon: fact.$1, label: fact.$2, value: fact.$3),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.7),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    color: tokens.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CollegeFacilitiesSection extends StatelessWidget {
  final CollegeModel college;

  const CollegeFacilitiesSection({required this.college, super.key});

  @override
  Widget build(BuildContext context) {
    final facilities = college.effectiveFacilities.labeledEntries;
    final available = facilities.where((e) => e.value).toList();
    final unavailable = facilities.where((e) => !e.value).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facilities',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...available.map(
              (e) => _FacilityChip(label: e.key, available: true),
            ),
            ...unavailable.map(
              (e) => _FacilityChip(label: e.key, available: false),
            ),
          ],
        ),
      ],
    );
  }
}

class _FacilityChip extends StatelessWidget {
  final String label;
  final bool available;

  const _FacilityChip({required this.label, required this.available});

  IconData get _icon {
    switch (label) {
      case 'Library':
        return Icons.local_library_outlined;
      case 'Labs':
        return Icons.science_outlined;
      case 'WiFi':
        return Icons.wifi;
      case 'Hostel':
        return Icons.hotel_outlined;
      case 'Sports':
        return Icons.sports_soccer_outlined;
      case 'Cafeteria':
        return Icons.restaurant_outlined;
      case 'Medical':
        return Icons.medical_services_outlined;
      case 'Transport':
        return Icons.directions_bus_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final color = available ? primary : tokens.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: available ? primary.withValues(alpha: 0.1) : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        border: Border.all(
          color: available
              ? primary.withValues(alpha: 0.25)
              : tokens.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (!available) ...[
            const SizedBox(width: 4),
            Icon(Icons.close, size: 14, color: tokens.textTertiary),
          ],
        ],
      ),
    );
  }
}

class CollegeProfileQuickCards extends StatelessWidget {
  final CollegeModel college;
  final VoidCallback? onPlacementsTap;
  final VoidCallback? onHostelTap;
  final VoidCallback? onFeesTap;

  const CollegeProfileQuickCards({
    required this.college,
    this.onPlacementsTap,
    this.onHostelTap,
    this.onFeesTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final placements = college.placements;
    final fees = college.fees;
    final hostel = college.hostel;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final cards = [
          _QuickCard(
            title: 'Placements',
            icon: Icons.work_outline,
            color: colorScheme.primary,
            lines: [
              if (placements.averagePackageLpa > 0)
                'Avg ${placements.averagePackageLpa} LPA',
              if (placements.placementPercentage > 0)
                '${placements.placementPercentage}% placed',
            ],
            onTap: onPlacementsTap,
          ),
          _QuickCard(
            title: 'Hostel',
            icon: Icons.hotel_outlined,
            color: colorScheme.tertiary,
            lines: [
              hostel.available ? 'Available' : 'Check details',
              if (hostel.annualFee > 0 || fees.hostelAnnual > 0)
                IndianCurrencyFormatter.format(
                  hostel.annualFee > 0 ? hostel.annualFee : fees.hostelAnnual,
                ),
            ],
            onTap: onHostelTap,
          ),
          _QuickCard(
            title: 'Fees',
            icon: Icons.payments_outlined,
            color: colorScheme.secondary,
            lines: [
              if (fees.tuitionMin > 0 || fees.tuitionMax > 0)
                '${IndianCurrencyFormatter.format(fees.tuitionMin)} – ${IndianCurrencyFormatter.format(fees.tuitionMax)}',
            ],
            onTap: onFeesTap,
          ),
        ];

        if (wide) {
          return Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: cards
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> lines;
  final VoidCallback? onTap;

  const _QuickCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.lines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = tokens.buttonRadius;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.plusJakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: tokens.textPrimary,
                      ),
                    ),
                    ...lines.map(
                      (line) => Text(
                        line,
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class CollegeAdmissionLinksSection extends StatelessWidget {
  final CollegeModel college;

  const CollegeAdmissionLinksSection({required this.college, super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = college.displayAdmissionLinks;
    if (links.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admission Links',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PremiumCard(
              radius: tokens.cardRadius,
              padding: EdgeInsets.zero,
              child: PremiumListRow(
                leadingIcon: Icons.link,
                iconColor: secondary,
                title: link,
                trailing: Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: tokens.textTertiary,
                ),
                onTap: () => _openUrl(context, link),
                showChevron: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CollegeCommunitySection extends ConsumerWidget {
  final CollegeModel college;

  const CollegeCommunitySection({required this.college, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(
      collegeCommunityFeedPreviewProvider((
        collegeId: college.id,
        collegeName: college.name,
      )),
    );
    final tokens = context.tokens;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: secondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined, color: secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Community',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(
                  RouteNames.collegeCommunityFeedPath(
                    college.id,
                    name: college.name,
                  ),
                ),
                child: const Text('Open Feed'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          feedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Join discussions with verified students at this college.',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No community posts yet. Be the first to start a discussion!',
                    style: AppFonts.plusJakarta(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                  ),
                );
              }
              return Column(
                children: posts
                    .map(
                      (post) => PremiumListRow(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: secondary.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: secondary,
                          ),
                        ),
                        title: post.isPoll ? post.pollQuestion : post.content,
                        subtitle:
                            '${post.authorDisplayName} · ${post.likeCount} likes',
                        showChevron: false,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                RouteNames.collegeCommunityFeedPath(
                  college.id,
                  name: college.name,
                ),
              ),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('View Community Feed'),
            ),
          ),
        ],
      ),
    );
  }
}

class CollegeProfileOverviewSections extends StatelessWidget {
  final CollegeModel college;
  final VoidCallback? onPlacementsTap;
  final VoidCallback? onHostelTap;
  final VoidCallback? onFeesTap;
  final VoidCallback? onReviewsTap;

  const CollegeProfileOverviewSections({
    required this.college,
    this.onPlacementsTap,
    this.onHostelTap,
    this.onFeesTap,
    this.onReviewsTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewSummaryPanel(college: college),
        if (onReviewsTap != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onReviewsTap,
              child: const Text('See all reviews'),
            ),
          ),
        const SizedBox(height: 8),
        CollegeProfileQuickCards(
          college: college,
          onPlacementsTap: onPlacementsTap,
          onHostelTap: onHostelTap,
          onFeesTap: onFeesTap,
        ),
        const SizedBox(height: 20),
        CollegeFacilitiesSection(college: college),
        const SizedBox(height: 20),
        CollegeAdmissionLinksSection(college: college),
        const SizedBox(height: 20),
        // The primary "Talk to a Verified Student" CTA now lives in the
        // profile hero (TalkToVerifiedStudentHero), directly under the
        // college name / rating / location — so it is not repeated here.
        CollegeCommunitySection(college: college),
      ],
    );
  }
}
