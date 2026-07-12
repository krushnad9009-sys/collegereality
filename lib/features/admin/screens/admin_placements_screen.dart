import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../placements/providers/placement_provider.dart';

class AdminPlacementsScreen extends ConsumerWidget {
  const AdminPlacementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPlacementSubmissionsProvider);
    final admin = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Approvals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No pending placement submissions',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.collegeName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.companyName} • ${item.jobRole}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      Text(
                        '${item.packageLpa} LPA • ${item.employmentLabel} • ${item.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.gray600,
                        ),
                      ),
                      if (item.branch != null)
                        Text(
                          'Branch: ${item.branch}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: admin == null
                                  ? null
                                  : () async {
                                      await ref
                                          .read(placementRepositoryProvider)
                                          .rejectSubmission(
                                            submissionId: item.id,
                                            adminUid: admin.uid,
                                            adminNote: 'Rejected by admin',
                                          );
                                      ref.invalidate(
                                        pendingPlacementSubmissionsProvider,
                                      );
                                    },
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: admin == null
                                  ? null
                                  : () async {
                                      await ref
                                          .read(placementRepositoryProvider)
                                          .approveSubmission(
                                            submissionId: item.id,
                                            adminUid: admin.uid,
                                          );
                                      ref.invalidate(
                                        pendingPlacementSubmissionsProvider,
                                      );
                                      ref.invalidate(
                                        collegeVerifiedPlacementStatsProvider(
                                          item.collegeId,
                                        ),
                                      );
                                    },
                              child: const Text('Approve'),
                            ),
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
