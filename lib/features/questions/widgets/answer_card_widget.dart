import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../providers/question_provider.dart';

class AnswerCardWidget extends ConsumerWidget {
  final AnswerModel answer;
  final QuestionModel question;
  final bool canMarkMostHelpful;
  final VoidCallback? onReport;

  const AnswerCardWidget({
    required this.answer,
    required this.question,
    this.canMarkMostHelpful = false,
    this.onReport,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final voteAsync = ref.watch(
      answerVoteProvider((questionId: question.id, answerId: answer.id)),
    );
    final userVote = voteAsync.valueOrNull;
    final date = DateFormat('MMM d, yyyy').format(answer.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: answer.isMostHelpful
              ? AppTheme.accentColor.withValues(alpha: 0.5)
              : AppTheme.gray200.withValues(alpha: 0.9),
          width: answer.isMostHelpful ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (answer.isMostHelpful)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      'Most Helpful Answer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _AuthorRow(
                    displayName: answer.authorDisplayName,
                    isAnonymous: answer.isAnonymous,
                    isVerified: answer.isVerifiedStudent,
                    authorId: answer.authorId,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.gray400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              answer.body,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _VoteButton(
                  icon: Icons.arrow_upward_rounded,
                  count: answer.upvoteCount,
                  isActive: userVote == QuestionConstants.voteUp,
                  onTap: authUser == null
                      ? null
                      : () => _vote(
                            ref,
                            context,
                            authUser.uid,
                            QuestionConstants.voteUp,
                          ),
                ),
                const SizedBox(width: 8),
                _VoteButton(
                  icon: Icons.arrow_downward_rounded,
                  count: answer.downvoteCount,
                  isActive: userVote == QuestionConstants.voteDown,
                  onTap: authUser == null
                      ? null
                      : () => _vote(
                            ref,
                            context,
                            authUser.uid,
                            QuestionConstants.voteDown,
                          ),
                ),
                const Spacer(),
                if (canMarkMostHelpful && !answer.isMostHelpful)
                  TextButton.icon(
                    onPressed: () => _markMostHelpful(ref, context, authUser!.uid),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      'Mark Helpful',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                if (onReport != null)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    color: AppTheme.gray500,
                    onPressed: onReport,
                    tooltip: 'Report answer',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _vote(
    WidgetRef ref,
    BuildContext context,
    String userId,
    String vote,
  ) async {
    try {
      await ref.read(questionRepositoryProvider).voteAnswer(
            questionId: question.id,
            answerId: answer.id,
            userId: userId,
            vote: vote,
          );
      ref.invalidate(
        answerVoteProvider((questionId: question.id, answerId: answer.id)),
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _markMostHelpful(
    WidgetRef ref,
    BuildContext context,
    String userId,
  ) async {
    try {
      await ref.read(questionRepositoryProvider).markMostHelpful(
            questionId: question.id,
            answerId: answer.id,
            userId: userId,
          );
      ref.invalidate(questionByIdProvider(question.id));
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Marked as most helpful',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }
}

class _AuthorRow extends StatelessWidget {
  final String displayName;
  final bool isAnonymous;
  final bool isVerified;
  final String authorId;

  const _AuthorRow({
    required this.displayName,
    required this.isAnonymous,
    required this.isVerified,
    required this.authorId,
  });

  @override
  Widget build(BuildContext context) {
    final nameWidget = Text(
      displayName,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );

    return Row(
      children: [
        Icon(
          isAnonymous ? Icons.visibility_off_outlined : Icons.school_outlined,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 6),
        if (!isAnonymous)
          InkWell(
            onTap: () => context.push(RouteNames.studentProfilePath(authorId)),
            child: nameWidget,
          )
        else
          nameWidget,
        if (isVerified) ...[
          const SizedBox(width: 4),
          const Icon(Icons.verified, size: 14, color: AppTheme.secondaryColor),
        ],
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : AppTheme.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.primaryColor : AppTheme.gray600,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppTheme.primaryColor : AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
