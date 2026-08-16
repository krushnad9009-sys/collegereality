import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// One quick-discovery chip — a course/category term or a city term.
class _DiscoveryTerm {
  final String label;
  final IconData icon;
  final bool isCity;

  const _DiscoveryTerm(this.label, this.icon, {this.isCity = false});
}

/// Horizontally scrolling row of quick-discovery chips shown right below
/// the hero search bar — courses/categories first, then popular cities.
/// All chips route through the existing college search screen's query
/// params, exactly like the category/city sections further down the page.
class HomeDiscoveryChips extends StatelessWidget {
  const HomeDiscoveryChips({super.key});

  static const _terms = [
    _DiscoveryTerm('Engineering', Icons.precision_manufacturing_rounded),
    _DiscoveryTerm('Medical', Icons.local_hospital_rounded),
    _DiscoveryTerm('MBA', Icons.business_center_rounded),
    _DiscoveryTerm('Law', Icons.gavel_rounded),
    _DiscoveryTerm('Pharmacy', Icons.medication_rounded),
    _DiscoveryTerm('Arts', Icons.palette_rounded),
    _DiscoveryTerm('Commerce', Icons.account_balance_rounded),
    _DiscoveryTerm('Nursing', Icons.health_and_safety_rounded),
    _DiscoveryTerm('Pune', Icons.location_city_rounded, isCity: true),
    _DiscoveryTerm('Mumbai', Icons.location_city_rounded, isCity: true),
    _DiscoveryTerm('Delhi', Icons.location_city_rounded, isCity: true),
    _DiscoveryTerm('Bengaluru', Icons.location_city_rounded, isCity: true),
    _DiscoveryTerm('Hyderabad', Icons.location_city_rounded, isCity: true),
    _DiscoveryTerm('Chennai', Icons.location_city_rounded, isCity: true),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _terms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final term = _terms[index];
          return _DiscoveryChip(
            term: term,
            onTap: () => context.go(
              term.isCity
                  ? '${RouteNames.collegeSearch}?city=${Uri.encodeComponent(term.label)}'
                  : '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(term.label)}',
            ),
          );
        },
      ),
    );
  }
}

class _DiscoveryChip extends StatelessWidget {
  final _DiscoveryTerm term;
  final VoidCallback onTap;

  const _DiscoveryChip({required this.term, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final color = term.isCity ? Theme.of(context).colorScheme.secondary : primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(term.icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                term.label,
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
