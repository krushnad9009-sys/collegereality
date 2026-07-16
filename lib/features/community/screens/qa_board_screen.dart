import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/community_provider.dart';
import '../services/community_firestore_service.dart';

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
          ? Center(
              child: Text(
                'Set your college in profile to use Q&A.',
                style: GoogleFonts.poppins(color: AppTheme.gray600),
              ),
            )
          : threadsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (threads) {
                if (threads.isEmpty) {
                  return Center(
                    child: Text(
                      'No questions yet. Be the first to ask!',
                      style: GoogleFonts.poppins(color: AppTheme.gray600),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          thread.isResolved ? Icons.check_circle : Icons.help_outline,
                          color: thread.isResolved
                              ? AppTheme.accentColor
                              : AppTheme.primaryColor,
                        ),
                        title: Text(
                          thread.title ?? 'Question',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(thread.lastMessageText ?? ''),
                        trailing: Text('${thread.replyCount} answers'),
                        onTap: () =>
                            context.push(RouteNames.communityChatPath(thread.id)),
                      ),
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
