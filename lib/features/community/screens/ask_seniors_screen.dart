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

class AskSeniorsScreen extends ConsumerStatefulWidget {
  const AskSeniorsScreen({super.key});

  @override
  ConsumerState<AskSeniorsScreen> createState() => _AskSeniorsScreenState();
}

class _AskSeniorsScreenState extends ConsumerState<AskSeniorsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    final threadsAsync = ref.watch(askSeniorsThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Seniors'),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Ask a Senior'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Your question'),
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
