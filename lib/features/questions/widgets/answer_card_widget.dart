import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../providers/question_provider.dart';
import '../utils/question_rich_text_utils.dart';
import 'answer_reply_section.dart';

class AnswerCardWidget extends ConsumerWidget {
  final AnswerModel answer;
  final QuestionModel question;
  final bool canMarkHelpful;
  final bool canAccept;
  final bool canReply;
  final VoidCallback? onReport;

  const AnswerCardWidget({
    required this.answer,
    required this.question,
    this.canMarkHelpful = false,
    this.canAccept = false,
    this.canReply = false,
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
          color: answer.isAccepted
              ? AppTheme.accentColor.withValues(alpha: 0.6)
              : answer.isMostHelpful
                  ? AppTheme.secondaryColor.withValues(alpha: 0.5)
                  : AppTheme.gray200.withValues(alpha: 0.9),
          width: answer.isAccepted || answer.isMostHelpful ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (answer.isAccepted)
              _Banner(
                icon: Icons.check_circle,
                label: 'Accepted Answer',
                color: AppTheme.accentColor,
              )
            else if (answer.isMostHelpful)
              _Banner(
                icon: Icons.emoji_events_outlined,
                label: 'Most Helpful Answer',
                color: AppTheme.secondaryColor,
              ),
            Row(
              children: [
                Expanded(
                  child: _AuthorRow(
                    displayName: answer.authorDisplayName,
                    isAnonymous: answer.isAnonymous,
                    reviewerBadge: answer.reviewerBadge,
                    authorId: answer.authorId,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) async {
                    if (value == 'report' && onReport != null) onReport!();
                    if (value == 'block' && authUser != null) {
                      await ref.read(questionRepositoryProvider).blockUser(
                            blockerId: authUser.uid,
                            blockedId: answer.authorId,
                          );
                      ref.invalidate(blockedUserIdsProvider);
                      if (context.mounted) {
                        SnackBarHelper.showSuccessSnackBar(
                          context,
                          message: 'User blocked',
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (onReport != null)
                      const PopupMenuItem(value: 'report', child: Text('Report')),
                    if (authUser != null && authUser.uid != answer.authorId)
                      const PopupMenuItem(value: 'block', child: Text('Block user')),
                  ],
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
            QuestionRichTextUtils.buildRichText(answer.body),
            if (answer.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: answer.imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      answer.imageUrls[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _VoteButton(
                  icon: Icons.arrow_upward_rounded,
                  count: answer.upvoteCount,
                  isActive: userVote == QuestionConstants.voteUp,
                  onTap: authUser == null
                      ? null
                      : () => _vote(ref, context, authUser.uid, QuestionConstants.voteUp),
                ),
                const SizedBox(width: 8),
                _VoteButton(
                  icon: Icons.arrow_downward_rounded,
                  count: answer.downvoteCount,
                  isActive: userVote == QuestionConstants.voteDown,
                  onTap: authUser == null
                      ? null
                      : () => _vote(ref, context, authUser.uid, QuestionConstants.voteDown),
                ),
                const Spacer(),
                if (canAccept && !answer.isAccepted)
                  TextButton.icon(
                    onPressed: authUser == null
                        ? null
                        : () => _accept(ref, context, authUser.uid),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text('Accept', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                if (canMarkHelpful && !answer.isMostHelpful)
                  TextButton.icon(
                    onPressed: authUser == null
                        ? null
                        : () => _markMostHelpful(ref, context, authUser.uid),
                    icon: const Icon(Icons.emoji_events_outlined, size: 16),
                    label: Text('Helpful', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
              ],
            ),
            AnswerReplySection(
              questionId: question.id,
              answer: answer,
              canReply: canReply,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _vote(WidgetRef ref, BuildContext context, String userId, String vote) async {
    try {
      await ref.read(questionRepositoryProvider).voteAnswer(
            questionId: question.id,
            answerId: answer.id,
            userId: userId,
            vote: vote,
          );
      ref.invalidate(answerVoteProvider((questionId: question.id, answerId: answer.id)));
      ref.invalidate(questionByIdProvider(question.id));
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _markMostHelpful(WidgetRef ref, BuildContext context, String userId) async {
    try {
      await ref.read(questionRepositoryProvider).markMostHelpful(
            questionId: question.id,
            answerId: answer.id,
            userId: userId,
          );
      ref.invalidate(questionByIdProvider(question.id));
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Marked as most helpful');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _accept(WidgetRef ref, BuildContext context, String userId) async {
    try {
      await ref.read(questionRepositoryProvider).acceptAnswer(
            questionId: question.id,
            answerId: answer.id,
            userId: userId,
          );
      ref.invalidate(questionByIdProvider(question.id));
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Answer accepted');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Banner({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final String displayName;
  final bool isAnonymous;
  final String? reviewerBadge;
  final String authorId;

  const _AuthorRow({
    required this.displayName,
    required this.isAnonymous,
    required this.reviewerBadge,
    required this.authorId,
  });

  @override
  Widget build(BuildContext context) {
    final nameWidget = Text(
      displayName,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
    );

    final badge = reviewerBadge;
    final showBadge = badge != null &&
        badge != VerificationConstants.badgeNone &&
        VerificationConstants.isApprovedStudentOrAlumni(
          badge,
          VerificationConstants.statusApproved,
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
        if (showBadge) ...[
          const SizedBox(width: 6),
          VerificationBadgeWidget(badge: badge, iconSize: 12),
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
