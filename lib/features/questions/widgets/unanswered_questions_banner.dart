import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/question_provider.dart';

class UnansweredQuestionsBanner extends ConsumerWidget {
  final String collegeId;
  final String collegeName;

  const UnansweredQuestionsBanner({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unansweredAsync = ref.watch(unansweredQuestionsProvider(collegeId));

    return unansweredAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (questions) {
        if (questions.isEmpty) return const SizedBox.shrink();

        final tokens = context.tokens;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warningColor.withValues(alpha: isDark ? 0.16 : 0.12),
                Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Text(
                    'Unanswered Questions',
                    style: AppFonts.plusJakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: tokens.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...questions.take(3).map(
                    (q) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        q.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textTertiary),
                      onTap: () => context.push(
                        RouteNames.collegeQuestionPath(collegeId, q.id),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
