import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/animations/app_animations.dart';

/// The Home screen's three primary actions, presented as one clean card
/// row: **Talk to a Verified Student** (the core USP — boldest treatment),
/// **AI Assistant**, and **Compare Colleges**. Replaces the scattered CTAs
/// that used to live inside the trust panel and the standalone compare
/// module.
class HomeCoreFeaturesGrid extends StatelessWidget {
  const HomeCoreFeaturesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final features = <_Feature>[
      _Feature(
        title: 'Talk to a\nVerified Student',
        caption: 'Real answers',
        icon: Icons.support_agent_rounded,
        gradient: [scheme.primary, scheme.secondary],
        onWhite: false,
        onTap: () => context.go(RouteNames.guidesDirectory),
      ),
      _Feature(
        title: 'AI\nAssistant',
        caption: 'Ask anything',
        icon: Icons.auto_awesome_rounded,
        gradient: [
          scheme.primary.withValues(alpha: 0.12),
          scheme.primary.withValues(alpha: 0.04),
        ],
        onWhite: true,
        accent: const Color(0xFF0369A1),
        onTap: () => context.go(RouteNames.assistant),
      ),
      _Feature(
        title: 'Compare\nColleges',
        caption: 'Side by side',
        icon: Icons.compare_arrows_rounded,
        gradient: [
          const Color(0xFF15803D).withValues(alpha: 0.12),
          const Color(0xFF15803D).withValues(alpha: 0.04),
        ],
        onWhite: true,
        accent: const Color(0xFF15803D),
        onTap: () => context.go(RouteNames.compare),
      ),
    ];

    // IntrinsicHeight gives the Row a bounded cross-axis so `stretch` can
    // make all three cards match the tallest one (the page's own vertical
    // extent is unbounded inside the scroll view).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(feature: features[i])
                  .animate()
                  .fadeIn(
                    delay: (60 * i).ms,
                    duration: 360.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    delay: (60 * i).ms,
                    duration: 360.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final String caption;
  final IconData icon;
  final List<Color> gradient;
  final bool onWhite;
  final Color? accent;
  final VoidCallback onTap;

  const _Feature({
    required this.title,
    required this.caption,
    required this.icon,
    required this.gradient,
    required this.onWhite,
    required this.onTap,
    this.accent,
  });
}

class _FeatureCard extends StatefulWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final f = widget.feature;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = f.onWhite ? tokens.textPrimary : Colors.white;
    final iconColor = f.onWhite
        ? (f.accent ?? tokens.textPrimary)
        : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: f.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: f.gradient,
            ),
            color: f.onWhite ? tokens.surfaceElevated : null,
            border: Border.all(
              color: f.onWhite
                  ? tokens.borderSubtle
                  : Colors.white.withValues(alpha: 0.18),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color:
                          (f.onWhite
                                  ? Colors.black
                                  : Theme.of(context).colorScheme.primary)
                              .withValues(alpha: f.onWhite ? 0.05 : 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: f.onWhite
                      ? (f.accent ?? tokens.textPrimary).withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(f.icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                f.title,
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: fg,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                f.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.plusJakarta(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: f.onWhite
                      ? tokens.textTertiary
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
