import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../colleges/providers/college_provider.dart';

class _CategoryDef {
  final String label;
  final IconData icon;

  const _CategoryDef(this.label, this.icon);
}

/// "Explore Colleges" — compact stream tiles sized to their content, one
/// restrained brand-teal color family throughout (differentiated by icon
/// and label only, never by a different hue per tile).
class ExploreCategoryGrid extends ConsumerWidget {
  const ExploreCategoryGrid({super.key});

  static const _categories = [
    _CategoryDef('Engineering', Icons.precision_manufacturing_rounded),
    _CategoryDef('Medical', Icons.local_hospital_rounded),
    _CategoryDef('MBA', Icons.business_center_rounded),
    _CategoryDef('Law', Icons.gavel_rounded),
    _CategoryDef('Pharmacy', Icons.medication_rounded),
    _CategoryDef('Arts', Icons.palette_rounded),
    _CategoryDef('Commerce', Icons.account_balance_rounded),
    _CategoryDef('Nursing', Icons.health_and_safety_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(collegeCategoryCountsProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final count = countsAsync.valueOrNull?[cat.label];
        return _CategoryTile(
          def: cat,
          color: primary,
          count: count,
          onTap: () => context.go(
            '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(cat.label)}',
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryDef def;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _CategoryTile({required this.def, required this.color, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 16, 9),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(def.icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    def.label,
                    style: AppFonts.plusJakarta(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                  ),
                  if (count != null && count! > 0)
                    Text(
                      '${count! >= 1000 ? '${(count! / 1000).toStringAsFixed(1)}k' : count} colleges',
                      style: AppFonts.plusJakarta(fontSize: 11.5, fontWeight: FontWeight.w500, color: tokens.textTertiary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
