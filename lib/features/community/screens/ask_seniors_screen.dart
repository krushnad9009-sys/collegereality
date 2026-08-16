import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/community_provider.dart';
import '../services/community_firestore_service.dart';
import '../widgets/community_thread_card.dart';

class AskSeniorsScreen extends ConsumerStatefulWidget {
  const AskSeniorsScreen({super.key});

  @override
  ConsumerState<AskSeniorsScreen> createState() => _AskSeniorsScreenState();
}

class _AskSeniorsScreenState extends ConsumerState<AskSeniorsScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    final threadsAsync = ref.watch(askSeniorsThreadsProvider);

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: tokens.surfaceElevated,
        title: Text(
          'Ask Seniors',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: tokens.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: user?.collegeId == null ? null : () => _createThread(context),
          ),
        ],
      ),
      body: user?.collegeId == null
          ? AsyncEmptyView(
              icon: Icons.school_outlined,
              title: 'Set your college first',
              subtitle: 'Add your college in Profile to ask seniors there.',
              action: OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.profile),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Go to Profile'),
              ),
            )
          : threadsAsync.when(
              loading: () => const ListSkeletonLoader(itemCount: 5),
              error: (e, _) => AsyncErrorView(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(askSeniorsThreadsProvider),
              ),
              data: (threads) {
                if (threads.isEmpty) {
                  return AsyncEmptyView(
                    icon: Icons.support_agent_outlined,
                    title: 'No questions yet',
                    subtitle: 'Be the first to ask a senior for advice.',
                    action: FilledButton.icon(
                      onPressed: () => _createThread(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ask a Senior'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return CommunityThreadCard(
                      thread: thread,
                      icon: Icons.support_agent_outlined,
                      color: AppTheme.warningColor,
                      replyLabel: 'replies',
                      onTap: () =>
                          context.push(RouteNames.communityChatPath(thread.id)),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _createThread(BuildContext context) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;

    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AskDialog(
        title: 'Ask a Senior',
        titleController: titleController,
        bodyController: bodyController,
        titleHint: 'Subject',
        bodyHint: 'Your question',
      ),
    );

    if (ok != true ||
        titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      titleController.dispose();
      bodyController.dispose();
      return;
    }

    try {
      final thread = await ref.read(communityServiceProvider).createThread(
            user: user,
            type: CommunityConstants.typeAskSeniors,
            title: titleController.text.trim(),
            initialMessage: bodyController.text.trim(),
          );
      titleController.dispose();
      bodyController.dispose();
      if (!context.mounted) return;
      context.push(RouteNames.communityChatPath(thread.id));
    } on CommunityException catch (e) {
      titleController.dispose();
      bodyController.dispose();
      if (!context.mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: e.message);
    }
  }
}

/// Shared premium dialog shell for the Ask Seniors / Q&A "start a thread"
/// prompts — tokens-based styling, rounded fields, consistent typography.
class _AskDialog extends StatelessWidget {
  final String title;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final String titleHint;
  final String bodyHint;

  const _AskDialog({
    required this.title,
    required this.titleController,
    required this.bodyController,
    required this.titleHint,
    required this.bodyHint,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.buttonRadius),
      borderSide: BorderSide(color: tokens.borderSubtle),
    );

    return AlertDialog(
      backgroundColor: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      title: Text(
        title,
        style: AppFonts.plusJakarta(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: tokens.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            style: AppFonts.plusJakarta(fontSize: 14, color: tokens.textPrimary),
            decoration: InputDecoration(
              labelText: titleHint,
              labelStyle: AppFonts.plusJakarta(fontSize: 13, color: tokens.textTertiary),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder.copyWith(
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: bodyController,
            maxLines: 4,
            style: AppFonts.plusJakarta(fontSize: 14, color: tokens.textPrimary),
            decoration: InputDecoration(
              labelText: bodyHint,
              labelStyle: AppFonts.plusJakarta(fontSize: 13, color: tokens.textTertiary),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder.copyWith(
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppFonts.plusJakarta(fontWeight: FontWeight.w600, color: tokens.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
            ),
          ),
          child: Text('Post', style: AppFonts.plusJakarta(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
