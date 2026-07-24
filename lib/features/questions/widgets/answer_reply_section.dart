import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../../../core/constants/verification_constants.dart';
import '../models/answer_model.dart';
import '../providers/question_provider.dart';
import '../utils/question_rich_text_utils.dart';

class AnswerReplySection extends ConsumerStatefulWidget {
  final String questionId;
  final AnswerModel answer;
  final bool canReply;

  const AnswerReplySection({
    required this.questionId,
    required this.answer,
    required this.canReply,
    super.key,
  });

  @override
  ConsumerState<AnswerReplySection> createState() => _AnswerReplySectionState();
}

class _AnswerReplySectionState extends ConsumerState<AnswerReplySection> {
  final _replyController = TextEditingController();
  bool _expanded = false;
  bool _submitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final user = await ref.read(currentUserDetailProvider.future);
      await ref.read(questionRepositoryProvider).createReply(
            questionId: widget.questionId,
            answerId: widget.answer.id,
            authorId: authUser.uid,
            displayName: user?.effectivePublicDisplayName,
            isAnonymous: user?.usesAnonymousPublicDisplayName ?? false,
            body: body,
          );
      _replyController.clear();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Reply posted');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(
      answerRepliesProvider((
        questionId: widget.questionId,
        answerId: widget.answer.id,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.answer.replyCount} repl${widget.answer.replyCount == 1 ? 'y' : 'ies'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          repliesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (replies) {
              return Column(
                children: replies.map((reply) {
                  return Container(
                    margin: const EdgeInsets.only(left: 12, bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reply.authorDisplayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (reply.reviewerBadge != null &&
                                reply.reviewerBadge !=
                                    VerificationConstants.badgeNone)
                              VerificationBadgeWidget(
                                badge: reply.reviewerBadge!,
                                iconSize: 10,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        QuestionRichTextUtils.buildRichText(reply.body),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (widget.canReply) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
