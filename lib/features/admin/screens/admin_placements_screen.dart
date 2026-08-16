import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
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
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView.fromError(e),
        data: (items) {
          if (items.isEmpty) {
            return const AsyncEmptyView(
              icon: Icons.work_outline,
              title: 'No pending submissions',
              subtitle: 'All placement submissions have been reviewed.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final tokens = context.tokens;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.collegeName,
                        style: AppFonts.plusJakarta(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.companyName} • ${item.jobRole}',
                        style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textPrimary),
                      ),
                      Text(
                        '${item.packageLpa} LPA • ${item.employmentLabel} • ${item.year}',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                      if (item.branch != null)
                        Text(
                          'Branch: ${item.branch}',
                          style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textPrimary),
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
