import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/college_constants.dart';
import '../../colleges/providers/college_provider.dart';

class _CategoryDef {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryDef(this.label, this.icon, this.color);
}

/// "Explore Colleges" — a strong grid of category tiles. Each tile is an
/// image-led "spotlight" card (tinted background, large icon, decorative
/// mark, real per-category college count) rather than a plain icon+text
/// row, so the grid reads as a deliberate product surface instead of a
/// generic settings-style list.
class ExploreCategoryGrid extends ConsumerWidget {
  const ExploreCategoryGrid({super.key});

  static const _categories = [
    _CategoryDef('Engineering', Icons.precision_manufacturing_rounded, Color(0xFF1E3A5F)),
    _CategoryDef('Medical', Icons.local_hospital_rounded, Color(0xFFB91C1C)),
    _CategoryDef('MBA', Icons.business_center_rounded, Color(0xFF0F766E)),
    _CategoryDef('Law', Icons.gavel_rounded, Color(0xFF5B21B6)),
    _CategoryDef('Pharmacy', Icons.medication_rounded, Color(0xFF0369A1)),
    _CategoryDef('Arts', Icons.palette_rounded, Color(0xFFBE185D)),
    _CategoryDef('Commerce', Icons.account_balance_rounded, Color(0xFFB45309)),
    _CategoryDef('Nursing', Icons.health_and_safety_rounded, Color(0xFF15803D)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(collegeCategoryCountsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 4 ? 1.05 : 1.35,
          ),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final count = countsAsync.valueOrNull?[cat.label];
            return _CategoryCard(
              def: cat,
              countLabel: count != null && count > 0
                  ? '${CollegeConstants.formatCollegeCount(count)}+ colleges'
                  : 'Explore now',
              onTap: () => context.go(
                '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(cat.label)}',
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryDef def;
  final String countLabel;
  final VoidCallback onTap;

  const _CategoryCard({required this.def, required this.countLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? def.color.withValues(alpha: 0.22) : def.color.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(color: def.color.withValues(alpha: isDark ? 0.28 : 0.16)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tint, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -14,
                bottom: -14,
                child: Icon(def.icon, size: 78, color: def.color.withValues(alpha: isDark ? 0.14 : 0.09)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [def.color, Color.lerp(def.color, Colors.black, 0.18) ?? def.color],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: def.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(def.icon, color: Colors.white, size: 21),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          def.label,
                          style: AppFonts.plusJakarta(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: tokens.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          countLabel,
                          style: AppFonts.plusJakarta(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: def.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
