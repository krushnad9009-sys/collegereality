import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/admin_route_resolver.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/review_card_widget.dart';
import '../../reviews/widgets/star_rating_widget.dart';
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

  // Cursor-paginated (20/page) instead of allReviewsAdminProvider's
  // one-shot 200-doc fetch -- mirrors AdminUsersScreen/AdminCollegesScreen.
  String? _cursor;
  bool _hasMore = false;
  List<ReviewModel> _reviews = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool loadMore = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(
        adminReviewPageProvider(
          AdminReviewPageParams(
            statusFilter: _statusFilter,
            startAfterDocumentId: loadMore ? _cursor : null,
          ),
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _reviews = loadMore ? [..._reviews, ...page.reviews] : page.reviews;
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setFilter(String? filter) {
    setState(() => _statusFilter = filter);
    _load();
  }

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
      ref.invalidate(collegeReviewsProvider(review.collegeId));
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: delete ? 'Review deleted' : 'Review updated to $status',
      );
      await _load();
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  /// Super Admin full-control edit: review content, every numeric rating
  /// the review carries (including legacy keys like `infrastructure` that
  /// no longer appear in [RatingParameters.categories] but still exist on
  /// older documents), and status -- including Delete, which reuses the
  /// existing confirmed [_moderate] delete path rather than writing an
  /// invalid status string.
  Future<void> _openFullEditDialog(ReviewModel review) async {
    final contentController = TextEditingController(text: review.textReview);
    final ratings = Map<String, double>.from(review.ratings);
    // Keep current-schema keys in their canonical order, then append any
    // legacy/unknown keys the review still carries so nothing is hidden.
    final ratingKeys = [
      ...RatingParameters.allKeys.where(ratings.containsKey),
      ...ratings.keys.where((k) => !RatingParameters.allKeys.contains(k)),
    ];
    var status = ReviewModel.normalizeStatus(review.status);

    final result = await showDialog<_ReviewEditResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Review (Super Admin)'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review content',
                    style: AppFonts.plusJakarta(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: contentController,
                    maxLines: 6,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ratings',
                    style: AppFonts.plusJakarta(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...ratingKeys.map(
                    (key) => RatingInputRow(
                      label: RatingParameters.labelFor(key),
                      value: ratings[key] ?? 0,
                      onChanged: (v) => setDialogState(() => ratings[key] = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Status',
                    style: AppFonts.plusJakarta(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                        value: ReviewModel.statusPublished,
                        child: Text('Publish'),
                      ),
                      DropdownMenuItem(
                        value: ReviewModel.statusPending,
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: ReviewModel.statusHidden,
                        child: Text('Hide'),
                      ),
                      DropdownMenuItem(
                        value: ReviewModel.statusRejected,
                        child: Text('Reject'),
                      ),
                      DropdownMenuItem(
                        value: _ReviewEditResult.deleteSentinel,
                        child: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => status = v ?? status),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                _ReviewEditResult(
                  textReview: contentController.text.trim(),
                  ratings: ratings,
                  status: status,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    contentController.dispose();
    if (result == null) return;

    if (result.status == _ReviewEditResult.deleteSentinel) {
      await _moderate(review, review.status, delete: true);
      return;
    }

    try {
      final repository = ref.read(reviewRepositoryProvider);
      await repository.adminUpdateReview(
        review.copyWith(
          textReview: result.textReview,
          ratings: result.ratings,
          status: result.status,
        ),
      );
      await ref.read(adminActionLoggerProvider).log(
            action: 'review.admin_override',
            targetId: review.id,
            targetType: 'review',
            metadata: {
              'status': result.status,
              'collegeId': review.collegeId,
            },
          );
      ref.invalidate(collegeReviewsProvider(review.collegeId));
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Review updated');
      await _load();
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => _setFilter(null),
                ),
                _FilterChip(
                  label: 'Published',
                  selected: _statusFilter == ReviewModel.statusPublished,
                  onTap: () => _setFilter(ReviewModel.statusPublished),
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: _statusFilter == ReviewModel.statusPending,
                  onTap: () => _setFilter(ReviewModel.statusPending),
                ),
                _FilterChip(
                  label: 'Hidden',
                  selected: _statusFilter == ReviewModel.statusHidden,
                  onTap: () => _setFilter(ReviewModel.statusHidden),
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: _statusFilter == ReviewModel.statusRejected,
                  onTap: () => _setFilter(ReviewModel.statusRejected),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _reviews.isEmpty
                ? const ReviewListSkeleton()
                : _error != null
                    ? AsyncErrorView.fromError(_error!, onRetry: _load)
                    : _reviews.isEmpty
                        ? Center(
                            child: Text(
                              'No reviews in this category',
                              style: AppFonts.plusJakarta(color: context.tokens.textTertiary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _reviews.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _reviews.length) {
                                return Center(
                                  child: _loading
                                      ? const Padding(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          child: CircularProgressIndicator(),
                                        )
                                      : TextButton(
                                          onPressed: () => _load(loadMore: true),
                                          child: const Text('Load more'),
                                        ),
                                );
                              }
                              final review = _reviews[index];
                              final isPublished =
                                  review.status == ReviewModel.statusPublished;
                              final isHidden =
                                  review.status == ReviewModel.statusHidden;
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
                                onEditContent: canEdit
                                    ? () => _openFullEditDialog(review)
                                    : null,
                                onDelete: () => _moderate(
                                  review,
                                  review.status,
                                  delete: true,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// Local holder for the full edit dialog's result -- avoids threading three
/// separate return values out of [showDialog].
class _ReviewEditResult {
  static const String deleteSentinel = '__delete__';

  final String textReview;
  final Map<String, double> ratings;
  final String status;

  const _ReviewEditResult({
    required this.textReview,
    required this.ratings,
    required this.status,
  });
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
