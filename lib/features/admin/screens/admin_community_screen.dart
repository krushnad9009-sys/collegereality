import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/admin_route_resolver.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
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
          onPressed: () => context.go(AdminRouteResolver.home(context)),
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
          final tokens = context.tokens;
          return Center(
            child: Text(
              'No open community reports',
              style: AppFonts.plusJakarta(color: tokens.textSecondary),
            ),
          );
        }
        final tokens = context.tokens;
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final report = reports[index];
            return PremiumCard(
              radius: tokens.cardRadius,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['reason']?.toString() ?? 'Report',
                    style: AppFonts.plusJakarta(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User: ${report['reportedId']}',
                    style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textSecondary),
                  ),
                  if (report['messageId'] != null)
                    Text(
                      'Message: ${report['messageId']}',
                      style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textSecondary),
                    ),
                  const SizedBox(height: AppSpacing.md),
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
                      const SizedBox(width: AppSpacing.sm),
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
          final tokens = context.tokens;
          return Center(
            child: Text(
              'No auto-hidden messages',
              style: AppFonts.plusJakarta(color: tokens.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = items[index];
            return PremiumCard(
              padding: EdgeInsets.zero,
              child: PremiumListRow(
                leadingIcon: Icons.visibility_off_outlined,
                title: item['text']?.toString() ?? 'Message',
                subtitle: 'Reports: ${item['reportCount'] ?? 0}',
                showChevron: false,
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
          final tokens = context.tokens;
          return Center(
            child: Text(
              'No spam-flagged messages',
              style: AppFonts.plusJakarta(color: tokens.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = items[index];
            return PremiumCard(
              padding: EdgeInsets.zero,
              child: PremiumListRow(
                leadingIcon: Icons.report_gmailerrorred_outlined,
                iconColor: Colors.redAccent,
                title: item['text']?.toString() ?? 'Message',
                subtitle: 'Flagged as spam',
                showChevron: false,
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
