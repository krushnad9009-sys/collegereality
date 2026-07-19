import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/question_model.dart';
import '../providers/question_provider.dart';

Future<QuestionModel?> showAskQuestionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String collegeId,
  required String collegeName,
}) async {
  final authUser = ref.read(authStateProvider).valueOrNull;
  if (authUser == null) {
    if (context.mounted) {
      context.go(RouteNames.login);
    }
    return null;
  }

  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  var isAnonymous = false;
  var isSubmitting = false;

  final result = await showModalBottomSheet<QuestionModel?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask a Student',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'About $collegeName',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.gray500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    maxLength: QuestionConstants.maxTitleLength,
                    decoration: InputDecoration(
                      labelText: 'Question title',
                      hintText: 'What do you want to know?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyController,
                    maxLines: 4,
                    maxLength: QuestionConstants.maxBodyLength,
                    decoration: InputDecoration(
                      labelText: 'Details (optional)',
                      hintText: 'Add more context...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Ask anonymously',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Your name will be hidden from other students',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.gray500,
                      ),
                    ),
                    value: isAnonymous,
                    onChanged: (v) => setState(() => isAnonymous = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setState(() => isSubmitting = true);
                              try {
                                final user = await ref.read(
                                  currentUserDetailProvider.future,
                                );
                                final question = await ref
                                    .read(questionRepositoryProvider)
                                    .createQuestion(
                                      collegeId: collegeId,
                                      collegeName: collegeName,
                                      authorId: authUser.uid,
                                      displayName: user?.displayName,
                                      isAnonymous: isAnonymous,
                                      title: titleController.text,
                                      body: bodyController.text,
                                    );
                                ref
                                    .read(optimisticQuestionsProvider.notifier)
                                    .addQuestion(collegeId, question);
                                if (context.mounted) {
                                  Navigator.pop(sheetContext, question);
                                }
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                if (context.mounted) {
                                  SnackBarHelper.showErrorSnackBar(
                                    context,
                                    message: e.toString(),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Ask a Student',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  titleController.dispose();
  bodyController.dispose();
  return result;
}

Future<void> showWriteAnswerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String questionId,
}) async {
  final authUser = ref.read(authStateProvider).valueOrNull;
  if (authUser == null) return;

  final bodyController = TextEditingController();
  var isAnonymous = false;
  var isSubmitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write an Answer',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bodyController,
                    maxLines: 6,
                    maxLength: QuestionConstants.maxAnswerLength,
                    decoration: InputDecoration(
                      hintText: 'Share your experience or advice...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Answer anonymously',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: isAnonymous,
                    onChanged: (v) => setState(() => isAnonymous = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setState(() => isSubmitting = true);
                              try {
                                final user = await ref.read(
                                  currentUserDetailProvider.future,
                                );
                                await ref
                                    .read(questionRepositoryProvider)
                                    .createAnswer(
                                      questionId: questionId,
                                      authorId: authUser.uid,
                                      displayName: user?.displayName,
                                      isAnonymous: isAnonymous,
                                      body: bodyController.text,
                                    );
                                if (context.mounted) {
                                  Navigator.pop(sheetContext);
                                  SnackBarHelper.showSuccessSnackBar(
                                    context,
                                    message: 'Answer posted',
                                  );
                                }
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                if (context.mounted) {
                                  SnackBarHelper.showErrorSnackBar(
                                    context,
                                    message: e.toString(),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Post Answer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  bodyController.dispose();
}

Future<void> showReportContentDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required Future<void> Function(String reason) onSubmit,
}) async {
  final reasonController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              try {
                await onSubmit(reason);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  SnackBarHelper.showSuccessSnackBar(
                    context,
                    message: 'Report submitted. Our team will review it.',
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  SnackBarHelper.showErrorSnackBar(
                    context,
                    message: e.toString(),
                  );
                }
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      );
    },
  );

  reasonController.dispose();
}
