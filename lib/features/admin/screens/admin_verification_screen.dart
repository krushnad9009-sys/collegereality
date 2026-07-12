import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../verification/providers/verification_provider.dart';
import '../../verification/services/verification_firestore_service.dart';

class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(verificationQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No pending verification requests',
                style: GoogleFonts.poppins(color: AppTheme.gray600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        VerificationConstants.documentLabel(
                          request.documentType,
                        ),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('User: ${request.userId}'),
                      Text(
                        'Status: ${request.status}',
                        style: GoogleFonts.poppins(color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.aiSummary,
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      if (request.aiFlags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: request.aiFlags
                              .map(
                                (f) => Chip(
                                  label: Text(f, style: const TextStyle(fontSize: 11)),
                                  backgroundColor:
                                      AppTheme.warningColor.withValues(alpha: 0.15),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _reject(context, ref, request.id),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approve(context, ref, request),
                            child: const Text('Approve'),
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

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    dynamic request,
  ) async {
    final adminId = ref.read(currentUserProvider)?.uid;
    if (adminId == null) return;

    try {
      await ref.read(verificationServiceProvider).approveRequest(
            requestId: request.id,
            adminId: adminId,
          );
      ref.invalidate(verificationQueueProvider);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Verification approved.');
      }
    } on VerificationException catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final adminId = ref.read(currentUserProvider)?.uid;
    if (adminId == null) return;

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject verification'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || noteController.text.trim().isEmpty) {
      noteController.dispose();
      return;
    }

    try {
      await ref.read(verificationServiceProvider).rejectRequest(
            requestId: requestId,
            adminId: adminId,
            adminNote: noteController.text.trim(),
          );
      ref.invalidate(verificationQueueProvider);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Verification rejected.');
      }
    } on VerificationException catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    } finally {
      noteController.dispose();
    }
  }
}
