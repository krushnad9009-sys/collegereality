import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// Closing statement for the Home scroll — a clean, quiet CTA rather than
/// another loud gradient card, so it reads as a deliberate "end of page"
/// moment with two clear next steps into existing functionality.
class HomeFinalCta extends StatelessWidget {
  const HomeFinalCta({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            'Your college decision deserves\nmore than advertisements.',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakarta(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go(RouteNames.collegeSearch),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(
                    'Explore Colleges',
                    style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(RouteNames.compare),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                  child: Text(
                    'Compare Colleges',
                    style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
