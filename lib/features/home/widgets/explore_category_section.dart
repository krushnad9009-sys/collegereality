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
    _CategoryDef(
      'Engineering',
      Icons.precision_manufacturing_rounded,
      Color(0xFF0F766E),
    ),
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
      // 60, not 56: at 56 the two-line (label + "N colleges") variant
      // overflows by ~1px once counts load, because the label/count Text
      // styles below don't pin an explicit line-height, so the font's
      // default metrics eat into the tile's vertical padding. Tightening
      // those text styles (see below) fixes the root cause; the extra 4px
      // here is deliberate headroom so a few pixels of font-metric
      // variance across browsers/OSes never reopens the same overflow.
      height: 60,
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

  const _CategoryTile({
    required this.def,
    required this.count,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = widget.def.color;
    // Contrast step: idle border alpha raised (0.22 -> 0.30) so pills read
    // clearly against the page background without losing the restrained,
    // editorial tone; hover/press states step up further for a clear,
    // smoothly-animated affordance.
    final borderAlpha = _pressed ? 0.5 : (_hovered ? 0.38 : 0.30);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
            decoration: BoxDecoration(
              color: _pressed
                  ? color.withValues(alpha: 0.08)
                  : tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: borderAlpha)),
              boxShadow: _hovered && !_pressed
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.def.icon, size: 17, color: color),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.def.label,
                      // Explicit height: font-metric line-height left
                      // unpinned is what caused the tile to overflow its
                      // fixed row height by ~1px once the count line below
                      // was present — pin both lines down tightly instead
                      // of just padding around the problem.
                      style: AppFonts.plusJakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (widget.count != null && widget.count! > 0)
                      Text(
                        '${widget.count! >= 1000 ? '${(widget.count! / 1000).toStringAsFixed(1)}k' : widget.count} colleges',
                        style: AppFonts.plusJakarta(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          color: tokens.textTertiary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
