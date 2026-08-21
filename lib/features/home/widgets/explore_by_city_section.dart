import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

class _CityDef {
  final String city;
  final String state;

  const _CityDef(this.city, this.state);
}

/// "Explore by City" — outlined by default so the row reads as a set of
/// calm navigation pills rather than solid colour blobs; depth comes from
/// a small tinted icon tile per pill, not a filled background.
class ExploreCityCarousel extends StatelessWidget {
  const ExploreCityCarousel({super.key});

  static const _cities = [
    _CityDef('Pune', 'Maharashtra'),
    _CityDef('Mumbai', 'Maharashtra'),
    _CityDef('Delhi', 'Delhi'),
    _CityDef('Bengaluru', 'Karnataka'),
    _CityDef('Hyderabad', 'Telangana'),
    _CityDef('Chennai', 'Tamil Nadu'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _cities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final city = _cities[index];
          return _CityChip(
            def: city,
            onTap: () => context.go(
              '${RouteNames.collegeSearch}?city=${Uri.encodeComponent(city.city)}&state=${Uri.encodeComponent(city.state)}',
            ),
          );
        },
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final _CityDef def;
  final VoidCallback onTap;

  const _CityChip({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          decoration: BoxDecoration(
            // Outlined, not a filled blob — a small tinted icon tile gives
            // depth instead.
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_city_rounded, color: colorScheme.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                def.city,
                style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
