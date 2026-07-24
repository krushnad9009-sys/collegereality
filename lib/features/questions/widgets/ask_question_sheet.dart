import 'package:file_picker/file_picker.dart';
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
import 'question_rich_text_field.dart';

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
  var selectedCategory = QuestionConstants.categoryAdmission;
  var isSubmitting = false;
  final imageUrls = <String>[];

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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: QuestionConstants.allCategories
                        .where((c) => c != QuestionConstants.categoryAll)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(QuestionConstants.categoryLabel(c)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  QuestionRichTextField(
                    controller: bodyController,
                    hint: 'Add details (optional)',
                    maxLength: QuestionConstants.maxBodyLength,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: imageUrls.length >= QuestionConstants.maxImagesPerPost
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            if (result == null || result.files.isEmpty) return;
                            final file = result.files.first;
                            if (file.bytes == null) return;
                            setState(() => isSubmitting = true);
                            try {
                              final url = await ref
                                  .read(questionStorageServiceProvider)
                                  .uploadImage(
                                    userId: authUser.uid,
                                    questionId: 'draft_${DateTime.now().millisecondsSinceEpoch}',
                                    bytes: file.bytes!,
                                    extension: file.extension ?? 'jpg',
                                  );
                              setState(() => imageUrls.add(url));
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showErrorSnackBar(
                                  context,
                                  message: e.toString(),
                                );
                              }
                            } finally {
                              setState(() => isSubmitting = false);
                            }
                          },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      imageUrls.isEmpty
                          ? 'Add image (optional)'
                          : '${imageUrls.length} image(s) attached',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your public display name from profile settings will be shown with your verification badge.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray500,
                    ),
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
                                      displayName: user?.effectivePublicDisplayName,
                                      isAnonymous:
                                          user?.usesAnonymousPublicDisplayName ??
                                              false,
                                      title: titleController.text,
                                      body: bodyController.text,
                                      category: selectedCategory,
                                      imageUrls: imageUrls,
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
  var isSubmitting = false;
  final imageUrls = <String>[];

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
                  QuestionRichTextField(
                    controller: bodyController,
                    hint: 'Share your experience or advice...',
                    maxLines: 6,
                    maxLength: QuestionConstants.maxAnswerLength,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result == null || result.files.isEmpty) return;
                      final file = result.files.first;
                      if (file.bytes == null) return;
                      try {
                        final url = await ref
                            .read(questionStorageServiceProvider)
                            .uploadImage(
                              userId: authUser.uid,
                              questionId: questionId,
                              bytes: file.bytes!,
                              extension: file.extension ?? 'jpg',
                              subPath: 'answers',
                            );
                        setState(() => imageUrls.add(url));
                      } catch (e) {
                        if (context.mounted) {
                          SnackBarHelper.showErrorSnackBar(
                            context,
                            message: e.toString(),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Attach image (optional)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your public display name from profile settings will be shown with your verification badge.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray500,
                    ),
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
                                      displayName: user?.effectivePublicDisplayName,
                                      isAnonymous:
                                          user?.usesAnonymousPublicDisplayName ??
                                              false,
                                      body: bodyController.text,
                                      imageUrls: imageUrls,
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
