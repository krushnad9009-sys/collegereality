import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// The one comparison feature on Home — a single strong module rather than
/// a thin CTA row, so "Compare Colleges" reads as a real decision-making
/// tool rather than another button.
class HomeCompareSection extends StatelessWidget {
  const HomeCompareSection({super.key});

  static const _dimensions = ['Fees', 'Placements', 'CR Score', 'Student Experience'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RouteNames.compare),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: tokens.surfaceElevated,
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.compare_arrows_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Compare colleges side by side',
                      style: AppFonts.plusJakarta(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Don\'t decide on one college alone — see how it stacks up.',
                style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w500, color: tokens.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dimensions
                    .map(
                      (d) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: tokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Text(
                          d,
                          style: AppFonts.plusJakarta(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Start comparing',
                    style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
