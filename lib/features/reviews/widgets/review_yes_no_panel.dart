import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final entries = ReviewYesNoQuestions.questions
        .where((q) => answers.containsKey(q.key))
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick answers',
          style: GoogleFonts.poppins(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((question) {
          final value = answers[question.key];
          if (value == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question.label,
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 11 : 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AnswerChip(value: value),
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
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
