import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/ask_question_sheet.dart';

/// Opens the Ask a Student sheet for a college.
class AskStudentButton extends ConsumerWidget {
  final String collegeId;
  final String collegeName;
  final bool extended;
  final bool outlined;
  final bool fab;

  const AskStudentButton({
    required this.collegeId,
    required this.collegeName,
    this.extended = false,
    this.outlined = false,
    this.fab = false,
    super.key,
  });

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(RouteNames.login);
      return;
    }
    await showAskQuestionSheet(
      context: context,
      ref: ref,
      collegeId: collegeId,
      collegeName: collegeName,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fab) {
      return FloatingActionButton.extended(
        heroTag: 'ask_student_$collegeId',
        elevation: 4,
        onPressed: () => _onPressed(context, ref),
        icon: const Icon(Icons.question_answer_outlined),
        label: const Text('Ask a Student'),
      );
    }

    if (extended) {
      return FloatingActionButton.extended(
        heroTag: 'ask_student_ext_$collegeId',
        elevation: 4,
        onPressed: () => _onPressed(context, ref),
        icon: const Icon(Icons.question_answer_outlined),
        label: const Text('Ask a Student'),
      );
    }

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: () => _onPressed(context, ref),
        icon: const Icon(Icons.question_answer_outlined, size: 18),
        label: Text(
          'Ask a Student',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () => _onPressed(context, ref),
      icon: const Icon(Icons.question_answer_outlined, size: 18),
      label: Text(
        'Ask a Student',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
