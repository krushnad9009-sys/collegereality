import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../community/providers/community_provider.dart';

class AdminCommunityScreen extends ConsumerWidget {
  const AdminCommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(communityReportsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: reportsAsync.when(
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      ),
    );
  }
}
