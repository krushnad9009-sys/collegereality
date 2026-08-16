import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/admin_route_resolver.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/review_card_widget.dart';
import '../providers/admin_provider.dart';
import '../services/admin_action_logger.dart';
import '../utils/admin_permissions.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String? _statusFilter;

  Future<void> _moderate(
    ReviewModel review,
    String status, {
    bool delete = false,
  }) async {
    try {
      final repository = ref.read(reviewRepositoryProvider);
      final logger = ref.read(adminActionLoggerProvider);
      if (delete) {
        await repository.deleteReview(review.id, review.collegeId);
        await logger.log(
          action: 'review.delete',
          targetId: review.id,
          targetType: 'review',
          metadata: {'collegeId': review.collegeId},
        );
      } else {
        await repository.updateReviewStatus(
          review.id,
          review.collegeId,
          status,
        );
        await logger.log(
          action: 'review.status',
          targetId: review.id,
          targetType: 'review',
          metadata: {'status': status, 'collegeId': review.collegeId},
        );
      }
      ref.invalidate(allReviewsAdminProvider(_statusFilter));
      ref.invalidate(collegeReviewsProvider(review.collegeId));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: delete ? 'Review deleted' : 'Review updated to $status',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _editContent(ReviewModel review) async {
    final controller = TextEditingController(text: review.textReview);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit review content'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null) return;
    try {
      final repository = ref.read(reviewRepositoryProvider);
      await repository.updateReview(review.copyWith(textReview: next));
      await ref.read(adminActionLoggerProvider).log(
            action: 'review.edit_content',
            targetId: review.id,
            targetType: 'review',
          );
      ref.invalidate(allReviewsAdminProvider(_statusFilter));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Review content updated');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(allReviewsAdminProvider(_statusFilter));
    final actor = ref.watch(currentUserModelProvider).valueOrNull;
    final canOverride = AdminPermissions.canOverrideReviews(actor?.userType);
    final canEdit = AdminPermissions.canEditReviewContent(actor?.userType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderate Reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AdminRouteResolver.home(context)),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                _FilterChip(
                  label: 'Published',
                  selected: _statusFilter == ReviewModel.statusPublished,
                  onTap: () => setState(
                    () => _statusFilter = ReviewModel.statusPublished,
                  ),
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: _statusFilter == ReviewModel.statusPending,
                  onTap: () => setState(
                    () => _statusFilter = ReviewModel.statusPending,
                  ),
                ),
                _FilterChip(
                  label: 'Hidden',
                  selected: _statusFilter == ReviewModel.statusHidden,
                  onTap: () => setState(
                    () => _statusFilter = ReviewModel.statusHidden,
                  ),
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: _statusFilter == ReviewModel.statusRejected,
                  onTap: () => setState(
                    () => _statusFilter = ReviewModel.statusRejected,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reviewsAsync.when(
              loading: () => const ReviewListSkeleton(),
              error: (e, _) => AsyncErrorView.fromError(
                e,
                onRetry: () =>
                    ref.invalidate(allReviewsAdminProvider(_statusFilter)),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  final tokens = context.tokens;
                  return Center(
                    child: Text(
                      'No reviews in this category',
                      style: AppFonts.plusJakarta(color: tokens.textTertiary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final isPublished =
                        review.status == ReviewModel.statusPublished;
                    final isHidden = review.status == ReviewModel.statusHidden;
                    return ReviewCardWidget(
                      review: review,
                      showCollegeName: true,
                      onApprove: isPublished
                          ? null
                          : () => _moderate(
                                review,
                                ReviewModel.statusPublished,
                              ),
                      onReject: review.status == ReviewModel.statusRejected
                          ? null
                          : () => _moderate(
                                review,
                                ReviewModel.statusRejected,
                              ),
                      onHide: !canOverride || isHidden
                          ? null
                          : () => _moderate(
                                review,
                                ReviewModel.statusHidden,
                              ),
                      onRestore: !canOverride || !isHidden
                          ? null
                          : () => _moderate(
                                review,
                                ReviewModel.statusPublished,
                              ),
                      onEditContent:
                          canEdit ? () => _editContent(review) : null,
                      onDelete: () => _moderate(
                        review,
                        review.status,
                        delete: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }
}
