import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_fonts.dart';

class _CityDef {
  final String city;
  final String state;

  const _CityDef(this.city, this.state);
}

/// "Explore by City" — compact cards in ONE brand-teal color family (depth
/// via elevation, not a different hue per city).
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: colorScheme.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                def.city,
                style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
