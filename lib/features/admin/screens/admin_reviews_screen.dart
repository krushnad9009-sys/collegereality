import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/review_card_widget.dart';

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
      if (delete) {
        await repository.deleteReview(review.id, review.collegeId);
      } else {
        await repository.updateReviewStatus(
          review.id,
          review.collegeId,
          status,
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

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(allReviewsAdminProvider(_statusFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderate Reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Text(
                      'No reviews in this category',
                      style: GoogleFonts.poppins(color: AppTheme.gray500),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final isPublished = review.status ==
                        ReviewModel.statusPublished;
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
      padding: const EdgeInsets.only(right: 8),
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
