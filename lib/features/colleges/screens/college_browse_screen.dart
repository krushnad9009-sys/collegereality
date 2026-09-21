import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/premium_list_row.dart';
import '../providers/city_category_counts_provider.dart';
import '../providers/college_provider.dart';
import '../utils/college_search_utils.dart';

/// Browse colleges by stream.
///
///  * No [city]: the all-India directory -- every stream with its overall
///    college count.
///  * With [city] (`/college-browse?city=Pune`, e.g. from a Home city badge):
///    only the streams that actually exist in that city, each with the exact
///    number of colleges IN that city ("45 colleges in Pune"). The all-India
///    counts are never shown while a city filter is active -- not while
///    loading, not on error.
class CollegeBrowseScreen extends ConsumerWidget {
  /// The city from the route (`?city=`); null/blank means no city filter.
  final String? city;

  const CollegeBrowseScreen({this.city, super.key});

  static const _styles = <String, (IconData, Color)>{
    'Engineering': (Icons.precision_manufacturing_rounded, Color(0xFF1E3A5F)),
    'Medical': (Icons.local_hospital_rounded, Color(0xFFB91C1C)),
    'MBA': (Icons.business_center_rounded, Color(0xFF0F766E)),
    'Law': (Icons.gavel_rounded, Color(0xFF5B21B6)),
    'Pharmacy': (Icons.medication_rounded, Color(0xFF0369A1)),
    'Arts': (Icons.palette_rounded, Color(0xFFBE185D)),
    'Commerce': (Icons.account_balance_rounded, Color(0xFFB45309)),
    'Science': (Icons.science_rounded, Color(0xFF15803D)),
    'Polytechnic': (Icons.build_rounded, Color(0xFF4B5563)),
    'Nursing': (Icons.health_and_safety_rounded, Color(0xFFDB2777)),
    'Agriculture': (Icons.agriculture_rounded, Color(0xFF65A30D)),
    'Architecture': (Icons.architecture_rounded, Color(0xFF7C3AED)),
  };

  /// The route's city, trimmed; null when absent or blank.
  String? get _city {
    final trimmed = city?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final selectedCity = _city;
    final cityLabel = selectedCity == null
        ? null
        : CollegeSearchUtils.titleCaseCity(selectedCity);

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          cityLabel == null ? 'Browse Colleges' : 'Colleges in $cityLabel',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: selectedCity == null
          ? const _AllIndiaBody()
          : _CityBody(city: selectedCity, cityLabel: cityLabel!),
    );
  }
}

/// The unfiltered directory: overall count per stream.
class _AllIndiaBody extends ConsumerWidget {
  const _AllIndiaBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final countsAsync = ref.watch(collegeCategoryCountsProvider);
    final totalAsync = ref.watch(collegeCountProvider);

    return countsAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 8),
      error: (e, _) => AsyncErrorView.fromError(
        e,
        onRetry: () => ref.invalidate(collegeCategoryCountsProvider),
      ),
      data: (counts) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            totalAsync.when(
              data: (total) => Text(
                CollegeConstants.acrossIndiaLabel(liveCount: total),
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => Text(
                CollegeConstants.acrossIndiaLabel(),
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final label in kBrowseCategoryLabels)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CategoryTile(
                  label: label,
                  subtitle: _subtitle(counts[label]),
                  onTap: () => context.go(
                    '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(label)}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String? _subtitle(int? count) =>
      count != null && count > 0 ? '$count colleges' : null;
}

/// One city: only the streams present there, with their exact in-city counts.
class _CityBody extends ConsumerWidget {
  final String city;
  final String cityLabel;

  const _CityBody({required this.city, required this.cityLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    // Same key for "pune", "Pune" and "PUNE" so they share one cached answer.
    final key = CollegeSearchUtils.normalizeCity(city);
    final countsAsync = ref.watch(cityCategoryCountsProvider(key));

    // No all-India fallback anywhere below: while loading or on error there
    // are simply no counts, never un-filtered ones.
    return countsAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 8),
      error: (e, _) => AsyncErrorView.fromError(
        e,
        onRetry: () => ref.invalidate(cityCategoryCountsProvider(key)),
      ),
      data: (counts) {
        // A stream with no college in this city would open an empty list.
        final available = [
          for (final label in kBrowseCategoryLabels)
            if ((counts[label] ?? 0) > 0) label,
        ];

        if (available.isEmpty) {
          return AsyncEmptyView(
            icon: Icons.location_city_outlined,
            title: 'No colleges found in $cityLabel',
            subtitle: 'Try another city, or browse all of India.',
            action: TextButton(
              onPressed: () => context.go(RouteNames.collegeBrowse),
              child: const Text('Browse all colleges'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: Icon(
                  Icons.location_city_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(cityLabel),
                deleteButtonTooltipMessage: 'Show all of India',
                onDeleted: () => context.go(RouteNames.collegeBrowse),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Streams available in $cityLabel',
              style: AppFonts.plusJakarta(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: tokens.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final label in available)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CategoryTile(
                  label: label,
                  subtitle: counts[label] == 1
                      ? '1 college in $cityLabel'
                      : '${counts[label]} colleges in $cityLabel',
                  // Search for this stream IN this city (not all of India).
                  onTap: () => context.go(
                    Uri(
                      path: RouteNames.collegeSearch,
                      queryParameters: {'category': label, 'city': cityLabel},
                    ).toString(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (icon, color) = CollegeBrowseScreen._styles[label]!;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: EdgeInsets.zero,
      child: PremiumListRow(
        leadingIcon: icon,
        iconColor: color,
        title: label,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
