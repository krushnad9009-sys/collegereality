import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../community/providers/community_provider.dart';
import '../../social/providers/social_provider.dart';

class AdminCommunityScreen extends ConsumerStatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  ConsumerState<AdminCommunityScreen> createState() => _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends ConsumerState<AdminCommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Auto-Hidden'),
            Tab(text: 'Spam'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsTab(),
          _AutoHiddenTab(),
          _SpamTab(),
        ],
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(communityReportsAdminProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Text(
              'No open community reports',
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text('User: ${report['reportedId']}'),
                    if (report['messageId'] != null)
                      Text('Message: ${report['messageId']}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(communityServiceProvider)
                                .updateCommunityReportStatus(
                                  report['id'] as String,
                                  CommunityConstants.reportStatusReviewed,
                                );
                            ref.invalidate(communityReportsAdminProvider);
                          },
                          child: const Text('Reviewed'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(communityServiceProvider)
                                .updateCommunityReportStatus(
                                  report['id'] as String,
                                  CommunityConstants.reportStatusActionTaken,
                                );
                            if (report['messageId'] != null) {
                              await ref
                                  .read(communityServiceProvider)
                                  .deleteMessage(report['messageId'] as String);
                            }
                            ref.invalidate(communityReportsAdminProvider);
                            if (context.mounted) {
                              SnackBarHelper.showSuccessSnackBar(
                                context,
                                message: 'Action taken',
                              );
                            }
                          },
                          child: const Text('Remove & Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AutoHiddenTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenAsync = ref.watch(autoHiddenMessagesAdminProvider);
    return hiddenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No auto-hidden messages',
              style: GoogleFonts.poppins(color: AppTheme.gray600),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item['text']?.toString() ?? 'Message'),
                subtitle: Text('Reports: ${item['reportCount'] ?? 0}'),
                trailing: TextButton(
                  onPressed: () async {
                    await ref
                        .read(socialRepositoryProvider)
                        .restoreMessage(item['id'] as String);
                    ref.invalidate(autoHiddenMessagesAdminProvider);
                  },
                  child: const Text('Restore'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SpamTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spamAsync = ref.watch(spamFlaggedMessagesAdminProvider);
    return spamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No spam-flagged messages',
              style: GoogleFonts.poppins(color: AppTheme.gray600),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item['text']?.toString() ?? 'Message'),
                subtitle: const Text('Flagged as spam'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(communityServiceProvider)
                        .deleteMessage(item['id'] as String);
                    ref.invalidate(spamFlaggedMessagesAdminProvider);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
