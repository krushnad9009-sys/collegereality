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
import '../../colleges/providers/college_provider.dart';

class CollegeBrowseScreen extends ConsumerWidget {
  const CollegeBrowseScreen({super.key});

  static const _categories = [
    ('Engineering', Icons.precision_manufacturing_rounded, Color(0xFF1E3A5F)),
    ('Medical', Icons.local_hospital_rounded, Color(0xFFB91C1C)),
    ('MBA', Icons.business_center_rounded, Color(0xFF0F766E)),
    ('Law', Icons.gavel_rounded, Color(0xFF5B21B6)),
    ('Pharmacy', Icons.medication_rounded, Color(0xFF0369A1)),
    ('Arts', Icons.palette_rounded, Color(0xFFBE185D)),
    ('Commerce', Icons.account_balance_rounded, Color(0xFFB45309)),
    ('Science', Icons.science_rounded, Color(0xFF15803D)),
    ('Polytechnic', Icons.build_rounded, Color(0xFF4B5563)),
    ('Nursing', Icons.health_and_safety_rounded, Color(0xFFDB2777)),
    ('Agriculture', Icons.agriculture_rounded, Color(0xFF65A30D)),
    ('Architecture', Icons.architecture_rounded, Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final countsAsync = ref.watch(collegeCategoryCountsProvider);
    final totalAsync = ref.watch(collegeCountProvider);

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          'Browse Colleges',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: countsAsync.when(
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
              ..._categories.map((entry) {
                final count = counts[entry.$1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CategoryTile(
                    label: entry.$1,
                    icon: entry.$2,
                    color: entry.$3,
                    count: count,
                    onTap: () => context.go(
                      '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(entry.$1)}',
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: EdgeInsets.zero,
      child: PremiumListRow(
        leadingIcon: icon,
        iconColor: color,
        title: label,
        subtitle: count != null && count! > 0 ? '$count colleges' : null,
        onTap: onTap,
      ),
    );
  }
}
