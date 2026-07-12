import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final q = initialQuery?.trim();
          if (q != null && q.isNotEmpty) {
            context.go('${RouteNames.assistant}?q=${Uri.encodeComponent(q)}');
          } else {
            context.go(RouteNames.assistant);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.08),
                AppTheme.secondaryColor.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask AI — colleges in English, Hindi, Marathi',
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.gray100
                            : AppTheme.gray800,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Best engineering in Pune • MBA under ₹5L • Hostel • Placements',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
