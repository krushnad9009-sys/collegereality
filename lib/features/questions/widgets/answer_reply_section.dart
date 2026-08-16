import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
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
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

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
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.answer.replyCount} repl${widget.answer.replyCount == 1 ? 'y' : 'ies'}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          repliesAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (replies) {
              return Column(
                children: replies.map((reply) {
                  return Container(
                    margin: const EdgeInsets.only(left: 12, bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.65),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reply.authorDisplayName,
                                style: AppFonts.plusJakarta(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
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
                        QuestionRichTextUtils.buildRichText(
                          reply.body,
                          baseStyle: AppFonts.plusJakarta(
                            fontSize: 13,
                            color: tokens.textSecondary,
                            height: 1.4,
                          ),
                        ),
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
                    style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      hintStyle: AppFonts.plusJakarta(fontSize: 13, color: tokens.textTertiary),
                      filled: true,
                      fillColor: tokens.surfaceMuted,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.65),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: primary),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
