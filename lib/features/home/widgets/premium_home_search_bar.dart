import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// The Home search input: a rounded, full-width white bar that sits on the
/// royal-blue hero. Tapping it opens the college search screen (which has
/// the real text field, filters and results).
class PremiumHomeSearchBar extends StatefulWidget {
  const PremiumHomeSearchBar({super.key});

  static const String hint = 'Find the right college';

  @override
  State<PremiumHomeSearchBar> createState() => _PremiumHomeSearchBarState();
}

class _PremiumHomeSearchBarState extends State<PremiumHomeSearchBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      label: 'Search colleges',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => context.go(RouteNames.collegeSearch),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              // Solid white: the brightest thing on the blue card.
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: tokens.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    PremiumHomeSearchBar.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakarta(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      // Slate 600 on white is ~7:1 -- clear, but reads as a
                      // placeholder rather than typed text.
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
