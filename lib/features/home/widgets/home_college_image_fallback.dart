import 'package:flutter/material.dart';

import '../../../config/theme/app_fonts.dart';

/// Calm, on-brand placeholder for compact college cards when no verified
/// cover photo exists — deliberately restrained (single brand-teal family,
/// no repeated wordmark) so a row of several fallback cards reads as
/// "premium placeholder", not a wall of identical rainbow stock art.
class CompactCollegeFallback extends StatelessWidget {
  final String initial;
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const CompactCollegeFallback({
    required this.initial,
    required this.height,
    required this.width,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.88),
            secondary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -height * 0.18,
            bottom: -height * 0.18,
            child: Icon(
              Icons.account_balance_rounded,
              size: height * 0.62,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Center(
            child: Text(
              initial,
              style: AppFonts.plusJakarta(
                fontSize: height * 0.32,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
