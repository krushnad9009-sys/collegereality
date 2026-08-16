import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

class _ActionDef {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _ActionDef(this.label, this.icon, this.color, this.route);
}

/// "What are you looking for?" — the primary-action modular grid: the six
/// core jobs a student comes to College Reality to do, each wired to its
/// existing screen/route. This is deliberately distinct from the stream
/// category grid below it — this is about *intent*, not subject area.
class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({super.key});

  static const _actions = [
    _ActionDef('Find Colleges', Icons.search_rounded, Color(0xFF0F766E), RouteNames.collegeSearch),
    _ActionDef('Compare Colleges', Icons.compare_arrows_rounded, Color(0xFF0369A1), RouteNames.compare),
    _ActionDef('Explore by Course', Icons.menu_book_rounded, Color(0xFF7C3AED), RouteNames.collegeBrowse),
    _ActionDef('Explore by City', Icons.map_rounded, Color(0xFFB45309), RouteNames.collegeSearch),
    _ActionDef('Check Placements', Icons.trending_up_rounded, Color(0xFF059669), RouteNames.rankingInsights),
    _ActionDef('Verified Reviews', Icons.reviews_rounded, Color(0xFFBE185D), RouteNames.community),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final action = _actions[index];
            return _ActionTile(def: action, onTap: () => context.go(action.route));
          },
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _ActionDef def;
  final VoidCallback onTap;

  const _ActionTile({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            border: Border.all(color: isDark ? tokens.borderSubtle.withValues(alpha: 0.6) : tokens.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(def.icon, size: 18, color: def.color),
              ),
              Text(
                def.label,
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
