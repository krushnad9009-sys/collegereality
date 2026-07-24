import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Question'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (question) {
          if (question == null) {
            return const Center(child: Text('Question not found'));
          }

          final canMarkHelpful = authUser != null && authUser.uid == question.authorId;
          final canAccept = canMarkHelpful;
          final canReply = canAnswerAsync.valueOrNull ?? false;

          return ListView(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            children: [
              if (question.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: Text(QuestionConstants.categoryLabel(question.category)),
                  ),
                ),
              Text(
                question.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (question.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                QuestionRichTextUtils.buildRichText(
                  question.body,
                  baseStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.gray700,
                    height: 1.5,
                  ),
                ),
              ],
              if (question.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: question.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    question.isAnonymous
                        ? Icons.visibility_off_outlined
                        : Icons.person_outline,
                    size: 16,
                    color: AppTheme.gray500,
                  ),
                  const SizedBox(width: 6),
                  if (!question.isAnonymous)
                    InkWell(
                      onTap: () => context.push(
                        RouteNames.studentProfilePath(question.authorId),
                      ),
                      child: Text(
                        question.authorDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  else
                    Text(
                      question.authorDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.gray600,
                      ),
                    ),
                  if (question.isAuthorVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: AppTheme.secondaryColor,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy').format(question.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Answers',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              canAnswerAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (canAnswer) {
                  if (!canAnswer) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(RouteNames.verification),
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text(
                          'Verify as a student or alumni of this college to answer',
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FilledButton.icon(
                      onPressed: () => showWriteAnswerSheet(
                        context: context,
                        ref: ref,
                        questionId: questionId,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                        'Write Answer',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
              answersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading answers: $e'),
                data: (answers) {
                  if (answers.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 48, color: AppTheme.gray300),
                          const SizedBox(height: 12),
                          Text(
                            'No answers yet',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verified students and alumni can share their experience',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.gray500,
                            ),
                          ),
                        ],
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
