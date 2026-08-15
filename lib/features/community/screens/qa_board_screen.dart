import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/community_provider.dart';
import '../services/community_firestore_service.dart';
import '../widgets/community_thread_card.dart';

class QaBoardScreen extends ConsumerStatefulWidget {
  const QaBoardScreen({super.key});

  @override
  ConsumerState<QaBoardScreen> createState() => _QaBoardScreenState();
}

class _QaBoardScreenState extends ConsumerState<QaBoardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    final threadsAsync = ref.watch(qaThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Q&A'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: user?.collegeId == null ? null : () => _createQuestion(context),
          ),
        ],
      ),
      body: user?.collegeId == null
          ? AsyncEmptyView(
              icon: Icons.school_outlined,
              title: 'Set your college first',
              subtitle: 'Add your college in Profile to use Q&A there.',
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
                onRetry: () => ref.invalidate(qaThreadsProvider),
              ),
              data: (threads) {
                if (threads.isEmpty) {
                  return AsyncEmptyView(
                    icon: Icons.quiz_outlined,
                    title: 'No questions yet',
                    subtitle: 'Be the first to ask a question.',
                    action: FilledButton.icon(
                      onPressed: () => _createQuestion(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ask a Question'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return CommunityThreadCard(
                      thread: thread,
                      icon: Icons.help_outline,
                      color: AppTheme.primaryColor,
                      replyLabel: 'answers',
                      onTap: () =>
                          context.push(RouteNames.communityChatPath(thread.id)),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _createQuestion(BuildContext context) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;

    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ask a Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
        ],
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
            type: CommunityConstants.typeQa,
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
