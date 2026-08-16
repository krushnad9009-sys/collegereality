import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/review_yes_no_questions.dart';

class ReviewYesNoPanel extends StatelessWidget {
  final Map<String, bool> answers;
  final bool compact;

  const ReviewYesNoPanel({
    required this.answers,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final entries = answers.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick answers',
          style: AppFonts.plusJakarta(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ReviewYesNoQuestions.labelFor(entry.key),
                    style: AppFonts.plusJakarta(
                      fontSize: compact ? 11 : 12,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AnswerChip(value: entry.value),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final bool value;

  const _AnswerChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value ? AppTheme.accentColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value ? 'Yes' : 'No',
        style: AppFonts.plusJakarta(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
