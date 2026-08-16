import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../engagement/providers/engagement_provider.dart';
import '../../../core/constants/question_constants.dart';
import '../providers/question_provider.dart';
import '../utils/question_rich_text_utils.dart';
import '../widgets/answer_card_widget.dart';
import '../widgets/ask_question_sheet.dart';

class QuestionDetailScreen extends ConsumerWidget {
  final String collegeId;
  final String questionId;

  const QuestionDetailScreen({
    required this.collegeId,
    required this.questionId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionByIdProvider(questionId));
    final answersAsync = ref.watch(sortedQuestionAnswersProvider(questionId));
    final canAnswerAsync = ref.watch(isVerifiedForCollegeAnswerProvider(collegeId));
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final savedIds = ref.watch(savedQuestionIdsProvider).valueOrNull ?? {};
    final isSaved = savedIds.contains(questionId);
    final isWide = MediaQuery.of(context).size.width >= 600;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: tokens.surfaceElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Question',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
            tooltip: isSaved ? 'Remove bookmark' : 'Save question',
            onPressed: authUser == null
                ? null
                : () async {
                    final repo = ref.read(engagementRepositoryProvider);
                    if (isSaved) {
                      await repo.unsaveQuestion(authUser.uid, questionId);
                    } else {
                      await repo.saveQuestion(
                        authUser.uid,
                        questionId,
                        collegeId: collegeId,
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: authUser == null
                ? null
                : () {
                    final question = questionAsync.valueOrNull;
                    if (question == null) return;
                    showReportContentDialog(
                      context: context,
                      ref: ref,
                      title: 'Report Question',
                      onSubmit: (reason) => ref
                          .read(questionRepositoryProvider)
                          .reportQuestion(
                            questionId: question.id,
                            collegeId: question.collegeId,
                            reporterId: authUser.uid,
                            reason: reason,
                          ),
                    );
                  },
          ),
        ],
      ),
      body: questionAsync.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView.fromError(e),
        data: (question) {
          if (question == null) {
            return const AsyncEmptyView(
              icon: Icons.help_outline_rounded,
              title: 'Question not found',
              subtitle: 'This question may have been removed.',
            );
          }

          final canMarkHelpful = authUser != null && authUser.uid == question.authorId;
          final canAccept = canMarkHelpful;
          final canReply = canAnswerAsync.valueOrNull ?? false;

          return ListView(
            padding: EdgeInsets.all(isWide ? AppSpacing.xxl : AppSpacing.lg),
            children: [
              if (question.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CategoryChip(category: question.category),
                ),
              Text(
                question.title,
                style: AppFonts.plusJakarta(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
              if (question.body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                QuestionRichTextUtils.buildRichText(
                  question.body,
                  baseStyle: AppFonts.plusJakarta(
                    fontSize: 14,
                    color: tokens.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
              if (question.imageUrls.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: question.imageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      child: Image.network(
                        question.imageUrls[i],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    question.isAnonymous
                        ? Icons.visibility_off_outlined
                        : Icons.person_outline,
                    size: 16,
                    color: tokens.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  if (!question.isAnonymous)
                    InkWell(
                      onTap: () => context.push(
                        RouteNames.studentProfilePath(question.authorId),
                      ),
                      child: Text(
                        question.authorDisplayName,
                        style: AppFonts.plusJakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Text(
                      question.authorDisplayName,
                      style: AppFonts.plusJakarta(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  if (question.isAuthorVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppTheme.secondaryColor,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy').format(question.createdAt),
                    style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Answers',
                style: AppFonts.plusJakarta(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              canAnswerAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (canAnswer) {
                  if (!canAnswer) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(RouteNames.verification),
                        icon: const Icon(Icons.verified_user_outlined, size: 18),
                        label: Text(
                          'Verify as a student or alumni of this college to answer',
                          style: AppFonts.plusJakarta(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: FilledButton.icon(
                      onPressed: () => showWriteAnswerSheet(
                        context: context,
                        ref: ref,
                        questionId: questionId,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        'Write Answer',
                        style: AppFonts.plusJakarta(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
              answersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: AsyncLoadingView(),
                ),
                error: (e, _) => AsyncErrorView.fromError(e, compact: true),
                data: (answers) {
                  if (answers.isEmpty) {
                    return SizedBox(
                      height: 220,
                      child: AsyncEmptyView(
                        icon: Icons.forum_outlined,
                        title: 'No answers yet',
                        subtitle:
                            'Verified students and alumni can share their experience',
                      ),
                    );
                  }

                  return Column(
                    children: answers
                        .map(
                          (answer) => AnswerCardWidget(
                            answer: answer,
                            question: question,
                            canMarkHelpful: canMarkHelpful,
                            canAccept: canAccept,
                            canReply: canReply,
                            onReport: authUser == null
                                ? null
                                : () => showReportContentDialog(
                                      context: context,
                                      ref: ref,
                                      title: 'Report Answer',
                                      onSubmit: (reason) => ref
                                          .read(questionRepositoryProvider)
                                          .reportAnswer(
                                            questionId: question.id,
                                            answerId: answer.id,
                                            collegeId: question.collegeId,
                                            reporterId: authUser.uid,
                                            reason: reason,
                                          ),
                                    ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        QuestionConstants.categoryLabel(category),
        style: AppFonts.plusJakarta(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}
