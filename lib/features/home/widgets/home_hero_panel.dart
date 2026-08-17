import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import 'home_discovery_chips.dart';
import 'premium_home_header.dart';
import 'premium_home_search_bar.dart';

/// The Home screen's single opening statement — greeting, search, and
/// quick discovery chips composed inside ONE elevated surface, instead of
/// three separate blocks stacked with gaps. This is the "unified hero"
/// every other section on the page is paced against.
class HomeHeroPanel extends StatelessWidget {
  final User? user;
  final String displayName;
  final String subtitle;

  const HomeHeroPanel({
    required this.user,
    required this.displayName,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            tokens.surfaceElevated,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumHomeHeader(user: user, displayName: displayName, subtitle: subtitle),
          const SizedBox(height: AppSpacing.lg),
          const PremiumHomeSearchBar(),
          const SizedBox(height: AppSpacing.md),
          const HomeDiscoveryChips(),
        ],
      ),
    );
  }
}
