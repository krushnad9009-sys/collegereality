import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/admin_route_resolver.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/firestore_user_service.dart';
import '../../verification/models/verification_request_model.dart';
import '../../verification/providers/verification_provider.dart';
import '../../verification/services/verification_firestore_service.dart';
import '../../verification/services/verification_storage_service.dart';

final _adminUserLoaderProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  return FirestoreUserService().getUserByUID(userId);
});

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
          onPressed: () => context.go(AdminRouteResolver.home(context)),
        ),
      ),
      body: queueAsync.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView.fromError(e),
        data: (requests) {
          if (requests.isEmpty) {
            return AsyncEmptyView(
              icon: Icons.verified_user_outlined,
              title: 'No pending requests',
              subtitle: 'All verification requests have been reviewed.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _VerificationReviewCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _VerificationReviewCard extends ConsumerWidget {
  final VerificationRequestModel request;

  const _VerificationReviewCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_adminUserLoaderProvider(request.userId));
    final tokens = context.tokens;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  VerificationConstants.documentLabel(request.documentType),
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              StatusBadge(
                label: VerificationConstants.roleLabel(request.verificationRole),
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          userAsync.when(
            loading: () => Text('User: ${request.userId}'),
            error: (_, _) => Text('User: ${request.userId}'),
            data: (user) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Unknown user',
                  style: AppFonts.plusJakarta(fontWeight: FontWeight.w600, color: tokens.textPrimary),
                ),
                Text(
                  user?.email ?? request.userId,
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (request.collegeName != null &&
              request.collegeName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'College: ${request.collegeName}',
              style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textPrimary),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Status: ${request.status}',
            style: AppFonts.plusJakarta(color: tokens.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            request.aiSummary,
            style: AppFonts.plusJakarta(fontSize: 13, color: tokens.textPrimary),
          ),
          if (request.aiFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: request.aiFlags
                  .map((f) => StatusBadge(label: f, color: AppTheme.warningColor))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _viewDocument(context),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View document'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _reject(context, ref),
                child: const Text('Reject'),
              ),
              OutlinedButton(
                onPressed: () => _requestResubmission(context, ref),
                child: const Text('Request resubmission'),
              ),
              ElevatedButton(
                onPressed: () => _approve(context, ref),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _viewDocument(BuildContext context) async {
    final storage = VerificationStorageService();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading document...'),
          ],
        ),
      ),
    );

    try {
      final bytes = await storage.downloadDocument(request.storagePath);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (bytes == null || bytes.isEmpty) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not load document.',
        );
        return;
      }

      final isPdf = request.storagePath.toLowerCase().endsWith('.pdf');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            VerificationConstants.documentLabel(request.documentType),
          ),
          content: SizedBox(
            width: 320,
            child: isPdf
                ? Text(
                    'PDF document uploaded (${bytes.length ~/ 1024} KB). '
                    'Download the file to review it.',
                    style: AppFonts.plusJakarta(fontSize: 13),
                  )
                : InteractiveViewer(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
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

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentUserProvider)?.uid;
    if (adminId == null) return;

    final note = await _adminNoteDialog(
      context,
      title: 'Reject verification',
      label: 'Reason for rejection',
      confirmLabel: 'Reject',
    );
    if (note == null || note.isEmpty) return;

    try {
      await ref.read(verificationServiceProvider).rejectRequest(
            requestId: request.id,
            adminId: adminId,
            adminNote: note,
          );
      ref.invalidate(verificationQueueProvider);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Verification rejected.');
      }
    } on VerificationException catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    }
  }

  Future<void> _requestResubmission(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentUserProvider)?.uid;
    if (adminId == null) return;

    final note = await _adminNoteDialog(
      context,
      title: 'Request resubmission',
      label: 'What should the user upload?',
      confirmLabel: 'Request resubmission',
    );
    if (note == null || note.isEmpty) return;

    try {
      await ref.read(verificationServiceProvider).requestResubmission(
            requestId: request.id,
            adminId: adminId,
            adminNote: note,
          );
      ref.invalidate(verificationQueueProvider);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Resubmission requested.',
        );
      }
    } on VerificationException catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    }
  }

  Future<String?> _adminNoteDialog(
    BuildContext context, {
    required String title,
    required String label,
    required String confirmLabel,
  }) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(labelText: label),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true || note.isEmpty) return null;
    return note;
  }
}
