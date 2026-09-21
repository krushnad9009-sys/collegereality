import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_fonts.dart';

class _ChipDef {
  final String label;
  final IconData icon;

  /// Soft pastel fill of the pill.
  final Color tint;

  /// Saturated colour of the icon.
  final Color accent;

  const _ChipDef(this.label, this.icon, this.tint, this.accent);
}

/// "Explore by stream" — ONE horizontally scrolling row of compact, rounded
/// pill chips, each with a soft pastel tint and a colourful icon:
///
///   Engineering (blue) · Medical (pink) · MBA (orange) · Law (teal) ·
///   Pharmacy (purple) · Arts (yellow) · Commerce (grey)
///
/// The labels are always dark slate: the pastel fills are light in both
/// themes, so dark ink keeps ~12:1+ contrast on every chip. Tapping a chip
/// opens college search filtered to that stream.
class ExploreCategoryChips extends StatelessWidget {
  const ExploreCategoryChips({super.key});

  /// Text colour on every chip (slate 900).
  static const Color ink = Color(0xFF0F172A);

  static const _chips = [
    _ChipDef(
      'Engineering',
      Icons.precision_manufacturing_rounded,
      Color(0xFFDBEAFE), // blue-100
      Color(0xFF2563EB), // blue-600
    ),
    _ChipDef(
      'Medical',
      Icons.local_hospital_rounded,
      Color(0xFFFCE7F3), // pink-100
      Color(0xFFDB2777), // pink-600
    ),
    _ChipDef(
      'MBA',
      Icons.business_center_rounded,
      Color(0xFFFFEDD5), // orange-100
      Color(0xFFEA580C), // orange-600
    ),
    _ChipDef(
      'Law',
      Icons.gavel_rounded,
      Color(0xFFCCFBF1), // teal-100
      Color(0xFF0D9488), // teal-600
    ),
    _ChipDef(
      'Pharmacy',
      Icons.medication_rounded,
      Color(0xFFEDE9FE), // violet-100
      Color(0xFF7C3AED), // violet-600
    ),
    _ChipDef(
      'Arts',
      Icons.palette_rounded,
      Color(0xFFFEF9C3), // yellow-100
      Color(0xFFA16207), // yellow-700 (600 is too pale on the tint)
    ),
    _ChipDef(
      'Commerce',
      Icons.account_balance_rounded,
      Color(0xFFE5E7EB), // gray-200 (a neutral grey, not blue-ish slate)
      Color(0xFF4B5563), // gray-600
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          return ActionChip(
            avatar: Icon(chip.icon, size: 18, color: chip.accent),
            label: Text(chip.label),
            labelStyle: AppFonts.plusJakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
            backgroundColor: chip.tint,
            // A whisper of the accent as an edge, so pale tints (yellow,
            // grey) still read as chips on the off-white page.
            side: BorderSide(color: chip.accent.withValues(alpha: 0.22)),
            shape: const StadiumBorder(),
            elevation: 0,
            pressElevation: 0,
            surfaceTintColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            visualDensity: VisualDensity.compact,
            onPressed: () => context.go(
              '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(chip.label)}',
            ),
          );
        },
      ),
    );
  }
}
