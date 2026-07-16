import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../student_life/providers/student_life_provider.dart';

class AdminStudentLifeScreen extends ConsumerWidget {
  const AdminStudentLifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postReportsAsync = ref.watch(postReportsAdminProvider);
    final commentReportsAsync = ref.watch(commentReportsAdminProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campus Life Moderation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.go(RouteNames.admin),
          ),
          bottom: const TabBar(tabs: [Tab(text: 'Post Reports'), Tab(text: 'Comment Reports')]),
        ),
        body: TabBarView(
          children: [
            postReportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (reports) => _reportsList(
                context,
                ref,
                reports,
                isPost: true,
              ),
            ),
            commentReportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (reports) => _reportsList(
                context,
                ref,
                reports,
                isPost: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportsList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> reports, {
    required bool isPost,
  }) {
    if (reports.isEmpty) {
      return Center(
        child: Text(
          'No open reports',
          style: GoogleFonts.poppins(color: AppTheme.gray600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['reason']?.toString() ?? 'Report',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text('Reporter: ${report['reporterId']}'),
                if (isPost) Text('Post: ${report['postId']}'),
                if (!isPost) Text('Comment: ${report['commentId']}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateStatus(ref, report['id'] as String, isPost,
                          StudentLifeConstants.reportStatusReviewed),
                      child: const Text('Reviewed'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _takeAction(ref, report, isPost),
                      child: const Text('Hide Content'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(
    WidgetRef ref,
    String reportId,
    bool isPost,
    String status,
  ) async {
    final repo = ref.read(studentLifeRepositoryProvider);
    if (isPost) {
      await repo.updatePostReportStatus(reportId, status);
      ref.invalidate(postReportsAdminProvider);
    } else {
      await repo.updateCommentReportStatus(reportId, status);
      ref.invalidate(commentReportsAdminProvider);
    }
  }

  Future<void> _takeAction(
    WidgetRef ref,
    Map<String, dynamic> report,
    bool isPost,
  ) async {
    final repo = ref.read(studentLifeRepositoryProvider);
    try {
      if (isPost) {
        await repo.hidePost(report['postId'] as String);
        await repo.updatePostReportStatus(
          report['id'] as String,
          StudentLifeConstants.reportStatusActionTaken,
        );
        ref.invalidate(postReportsAdminProvider);
      } else {
        await repo.hideComment(
          report['postId'] as String,
          report['commentId'] as String,
        );
        await repo.updateCommentReportStatus(
          report['id'] as String,
          StudentLifeConstants.reportStatusActionTaken,
        );
        ref.invalidate(commentReportsAdminProvider);
      }
    } catch (e) {
      // Admin screen — errors surfaced via snackbar in calling context if needed
    }
  }
}
