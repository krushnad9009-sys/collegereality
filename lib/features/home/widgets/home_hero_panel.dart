import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import 'app_header.dart';
import 'premium_home_header.dart';
import 'premium_home_search_bar.dart';

/// The Home hero: a full-width, solid deep royal-blue header with rounded
/// BOTTOM corners that holds, top to bottom:
///
///  1. the top bar   — hamburger · title · search · filter · bell · avatar
///  2. the greeting  — "Good afternoon, dk007" + its subtitle (white text)
///  3. the search bar — a rounded, full-width white input ("Find the right
///                      college")
///
/// It bleeds to the screen edges and under the status bar (the top inset is
/// added as padding), so the page starts as one confident block of colour.
class HomeHeroPanel extends StatelessWidget {
  final User? user;
  final String displayName;
  final String subtitle;
  final VoidCallback onMenuPressed;

  const HomeHeroPanel({
    required this.user,
    required this.displayName,
    required this.subtitle,
    required this.onMenuPressed,
    super.key,
  });

  /// Radius of the rounded bottom corners.
  static const double bottomRadius = 28;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.heroColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.heroColor.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                homeContentGutter(context),
                AppSpacing.md,
                homeContentGutter(context),
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeTopBar(user: user, onMenuPressed: onMenuPressed),
                  const SizedBox(height: AppSpacing.xl),
                  PremiumHomeHeader(
                    user: user,
                    displayName: displayName,
                    subtitle: subtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const PremiumHomeSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
