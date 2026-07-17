import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/premium_components.dart';

class AiSearchBar extends StatelessWidget {
  final String? initialQuery;
  final bool compact;

  const AiSearchBar({
    this.initialQuery,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      radius: AppSpacing.radiusXl,
      padding: EdgeInsets.zero,
      onTap: () {
        final q = initialQuery?.trim();
        if (q != null && q.isNotEmpty) {
          context.go('${RouteNames.assistant}?q=${Uri.encodeComponent(q)}');
        } else {
          context.go(RouteNames.assistant);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.primaryDark.withValues(alpha: 0.35),
                    AppTheme.secondaryDark.withValues(alpha: 0.2),
                  ]
                : [
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                    AppTheme.secondaryColor.withValues(alpha: 0.06),
                  ],
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: compact ? 14 : 18,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Assistant',
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? AppTheme.gray100 : AppTheme.gray900,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Find colleges, compare fees, placements & more',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
