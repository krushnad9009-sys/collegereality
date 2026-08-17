import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// The single dominant search affordance on Home — lives inside
/// [HomeHeroPanel]'s one elevated surface, so it carries no card chrome of
/// its own (no nested "card inside a card"), just a tappable content row.
class PremiumHomeSearchBar extends StatefulWidget {
  const PremiumHomeSearchBar({super.key});

  @override
  State<PremiumHomeSearchBar> createState() => _PremiumHomeSearchBarState();
}

class _PremiumHomeSearchBarState extends State<PremiumHomeSearchBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.go(RouteNames.collegeSearch),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find the right college',
                      style: AppFonts.plusJakarta(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'College, city, course or exam',
                      style: AppFonts.plusJakarta(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.tune_rounded, color: tokens.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
