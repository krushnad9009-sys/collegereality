import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

class _CityDef {
  final String city;
  final String state;
  final IconData icon;
  final Color color;

  const _CityDef(this.city, this.state, this.icon, this.color);
}

/// "Explore by City" — a horizontal row of compact gradient city cards,
/// visually distinct from both the category grid and the college carousels.
/// Tapping a city routes into the existing college search screen with the
/// same city/state query params used elsewhere in the app.
class ExploreCityCarousel extends StatelessWidget {
  const ExploreCityCarousel({super.key});

  static const _cities = [
    _CityDef('Pune', 'Maharashtra', Icons.terrain_rounded, Color(0xFF0F766E)),
    _CityDef('Mumbai', 'Maharashtra', Icons.apartment_rounded, Color(0xFF0369A1)),
    _CityDef('Delhi', 'Delhi', Icons.account_balance_rounded, Color(0xFF7C3AED)),
    _CityDef('Bengaluru', 'Karnataka', Icons.memory_rounded, Color(0xFF059669)),
    _CityDef('Hyderabad', 'Telangana', Icons.location_city_rounded, Color(0xFFB45309)),
    _CityDef('Chennai', 'Tamil Nadu', Icons.waves_rounded, Color(0xFFB91C1C)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _cities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final city = _cities[index];
          return _CityCard(
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

class _CityCard extends StatelessWidget {
  final _CityDef def;
  final VoidCallback onTap;

  const _CityCard({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Container(
          width: 118,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [def.color, Color.lerp(def.color, Colors.black, 0.22) ?? def.color],
            ),
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(def.icon, color: Colors.white.withValues(alpha: 0.92), size: 20),
              Text(
                def.city,
                style: AppFonts.plusJakarta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
