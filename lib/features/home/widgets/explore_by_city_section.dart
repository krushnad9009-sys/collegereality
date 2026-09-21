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

/// "Explore by City" — a horizontally scrolling row of circular badges: a
/// solid blue city icon inside a tinted, outlined circle, with the city name
/// underneath. Each badge routes into search with the city (and its state).
class ExploreCityCarousel extends StatelessWidget {
  const ExploreCityCarousel({super.key});

  static const _cities = [
    _CityDef('Mumbai', 'Maharashtra'),
    _CityDef('Pune', 'Maharashtra'),
    _CityDef('Delhi', 'Delhi'),
    _CityDef('Bengaluru', 'Karnataka'),
    _CityDef('Chennai', 'Tamil Nadu'),
    _CityDef('Hyderabad', 'Telangana'),
  ];

  /// Circle diameter + label + gaps.
  static const double _height = 64 + 8 + 20;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _cities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final city = _cities[index];
          return _CityBadge(
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

class _CityBadge extends StatefulWidget {
  final _CityDef def;
  final VoidCallback onTap;

  const _CityBadge({required this.def, required this.onTap});

  @override
  State<_CityBadge> createState() => _CityBadgeState();
}

class _CityBadgeState extends State<_CityBadge> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final flat = tokens.flatSurfaces;
    // Premium: solid royal-blue icon on an indigo-tint circle with a clear
    // outline. Elsewhere: the brand primary on a soft primary tint.
    final iconColor = flat ? tokens.heroColor : scheme.primary;
    final fill = flat
        ? tokens.chipFill
        : scheme.primary.withValues(alpha: 0.10);
    final edge = flat
        ? tokens.chipBorder
        : scheme.primary.withValues(alpha: 0.22);

    return Semantics(
      button: true,
      label: widget.def.city,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                      border: Border.all(color: edge, width: 1.5),
                      boxShadow: tokens.cardShadow,
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 30,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.def.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
