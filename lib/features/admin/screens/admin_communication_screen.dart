import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/widgets/index.dart';
import '../../communication/providers/communication_provider.dart';

class AdminCommunicationScreen extends ConsumerWidget {
  const AdminCommunicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Moderation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
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
                        report.reason,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported user: ${report.reportedId}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.gray600,
                        ),
                      ),
                      if (report.details.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(report.details),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(communicationServiceProvider)
                                  .updateReportStatus(
                                    report.id,
                                    CommunicationConstants.reportStatusReviewed,
                                  );
                              ref.invalidate(adminReportsProvider);
                              if (context.mounted) {
                                SnackBarHelper.showSuccessSnackBar(
                                  context,
                                  message: 'Marked as reviewed',
                                );
                              }
                            },
                            child: const Text('Reviewed'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(communicationServiceProvider)
                                  .updateReportStatus(
                                    report.id,
                                    CommunicationConstants
                                        .reportStatusActionTaken,
                                  );
                              ref.invalidate(adminReportsProvider);
                              if (context.mounted) {
                                SnackBarHelper.showSuccessSnackBar(
                                  context,
                                  message: 'Action recorded',
                                );
                              }
                            },
                            child: const Text('Action Taken'),
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
