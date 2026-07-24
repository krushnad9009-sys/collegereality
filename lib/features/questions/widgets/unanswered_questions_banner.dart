import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
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
      error: (_, __) => const SizedBox.shrink(),
      data: (questions) {
        if (questions.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warningColor.withValues(alpha: 0.12),
                AppTheme.primaryColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Text(
                    'Unanswered Questions',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
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
