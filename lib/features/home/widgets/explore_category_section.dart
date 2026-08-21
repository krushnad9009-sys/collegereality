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
  final Color color;

  const _CategoryDef(this.label, this.icon, this.color);
}

/// "Explore Colleges" — a horizontally scrolling stream row. Each stream
/// keeps its own soft tinted icon tile (restrained, editorial tones, not a
/// rainbow of saturated hues) so streams are told apart at a glance instead
/// of every tile looking like an identical grey box.
class ExploreCategoryGrid extends ConsumerWidget {
  const ExploreCategoryGrid({super.key});

  static const _categories = [
    _CategoryDef('Engineering', Icons.precision_manufacturing_rounded, Color(0xFF0F766E)),
    _CategoryDef('Medical', Icons.local_hospital_rounded, Color(0xFFB91C63)),
    _CategoryDef('MBA', Icons.business_center_rounded, Color(0xFF0369A1)),
    _CategoryDef('Law', Icons.gavel_rounded, Color(0xFF5C4D7D)),
    _CategoryDef('Pharmacy', Icons.medication_rounded, Color(0xFF15803D)),
    _CategoryDef('Arts', Icons.palette_rounded, Color(0xFFB5651D)),
    _CategoryDef('Commerce', Icons.account_balance_rounded, Color(0xFF3D5A80)),
    _CategoryDef('Nursing', Icons.health_and_safety_rounded, Color(0xFF7B2D26)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(collegeCategoryCountsProvider);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final count = countsAsync.valueOrNull?[cat.label];
          return _CategoryTile(
            def: cat,
            count: count,
            onTap: () => context.go(
              '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(cat.label)}',
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final _CategoryDef def;
  final int? count;
  final VoidCallback onTap;

  const _CategoryTile({required this.def, required this.count, required this.onTap});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = widget.def.color;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(10, 9, 16, 9),
          decoration: BoxDecoration(
            color: _pressed ? color.withValues(alpha: 0.08) : tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: _pressed ? 0.4 : 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(widget.def.icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.def.label,
                    style: AppFonts.plusJakarta(fontSize: 14, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                  ),
                  if (widget.count != null && widget.count! > 0)
                    Text(
                      '${widget.count! >= 1000 ? '${(widget.count! / 1000).toStringAsFixed(1)}k' : widget.count} colleges',
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
