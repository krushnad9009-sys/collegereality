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
import '../../reviews/models/review_page_model.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // null = All Ratings; '5'/'4'/'3' = that exact star bucket; '1-2' = 1 or 2.
  String? _ratingFilter;

  // Two independent data modes, mirroring AdminUsersScreen:
  //  * no search text and no rating filter -> cursor-paginated (20/page)
  //    listing via adminReviewPageProvider.
  //  * search text and/or a rating filter active -> a single bounded
  //    (200-doc) fetch via allReviewsAdminProvider, then EVERY keystroke
  //    re-filters that already-fetched list client-side (see
  //    _visibleReviews) rather than re-querying Firestore per character --
  //    "real-time" filtering on the fetched list, not a live search API.
  String? _cursor;
  bool _hasMore = false;
  List<ReviewModel> _reviews = [];
  bool _loading = false;
  String? _error;

  bool get _isFiltering =>
      _searchQuery.trim().isNotEmpty || _ratingFilter != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isFiltering) {
        final reviews =
            await ref.read(allReviewsAdminProvider(_statusFilter).future);
        if (!mounted) return;
        setState(() {
          _reviews = reviews;
          _cursor = null;
          _hasMore = false;
        });
        return;
      }

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

  void _onSearchChanged(String value) {
    final wasFiltering = _isFiltering;
    setState(() => _searchQuery = value);
    // Only re-fetch when switching data mode (into or out of filtering) --
    // every other keystroke just re-filters the pool already in _reviews
    // via the getter below, no network call.
    if (_isFiltering != wasFiltering) _load();
  }

  void _onRatingFilterChanged(String? value) {
    final wasFiltering = _isFiltering;
    setState(() => _ratingFilter = value);
    if (_isFiltering != wasFiltering) _load();
  }

  bool _matchesRatingFilter(ReviewModel review) {
    if (_ratingFilter == null) return true;
    final bucket = RatingDistribution.starBucketFor(review.overallRating);
    switch (_ratingFilter) {
      case '5':
        return bucket == 5;
      case '4':
        return bucket == 4;
      case '3':
        return bucket == 3;
      case '1-2':
        return bucket <= 2;
      default:
        return true;
    }
  }

  /// Client-side, case-insensitive filter over the currently-fetched
  /// [_reviews] -- college name, reviewer alias/userId, and review text.
  /// Runs on every build (cheap: a bounded in-memory list, not a network
  /// call), which is what makes typing feel instant.
  List<ReviewModel> get _visibleReviews {
    final query = _searchQuery.trim().toLowerCase();
    return _reviews.where((r) {
      if (!_matchesRatingFilter(r)) return false;
      if (query.isEmpty) return true;
      return r.collegeName.toLowerCase().contains(query) ||
          r.anonymousAlias.toLowerCase().contains(query) ||
          r.userId.toLowerCase().contains(query) ||
          r.textReview.toLowerCase().contains(query);
    }).toList();
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
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by college name, reviewer name/ID, or review text',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
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
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _ratingFilter,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Ratings')),
                    DropdownMenuItem(value: '5', child: Text('5 Stars')),
                    DropdownMenuItem(value: '4', child: Text('4 Stars')),
                    DropdownMenuItem(value: '3', child: Text('3 Stars')),
                    DropdownMenuItem(value: '1-2', child: Text('1-2 Stars')),
                  ],
                  onChanged: _onRatingFilterChanged,
                ),
              ],
            ),
          ),
          if (_isFiltering && !_loading && _reviews.length >= 200)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Text(
                'Searching the 200 most recent matching reviews -- narrow the '
                'status filter for an older review that isn\'t showing up.',
                style: AppFonts.plusJakarta(fontSize: 11.5, color: context.tokens.textTertiary),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                final visible = _visibleReviews;
                if (_loading && _reviews.isEmpty) return const ReviewListSkeleton();
                if (_error != null) {
                  return AsyncErrorView.fromError(_error!, onRetry: _load);
                }
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      _isFiltering
                          ? 'No reviews match your search/filters'
                          : 'No reviews in this category',
                      style: AppFonts.plusJakarta(color: context.tokens.textTertiary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  // "Load more" only makes sense in the paginated (non-
                  // filtering) mode -- the filtered pool is already
                  // everything that was fetched.
                  itemCount: visible.length + (!_isFiltering && _hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == visible.length) {
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
                    final review = visible[index];
                    final isPublished =
                        review.status == ReviewModel.statusPublished;
                    final isHidden = review.status == ReviewModel.statusHidden;
                    return ReviewCardWidget(
                      review: review,
                      showCollegeName: true,
                      onApprove: isPublished
                          ? null
                          : () => _moderate(review, ReviewModel.statusPublished),
                      onReject: review.status == ReviewModel.statusRejected
                          ? null
                          : () => _moderate(review, ReviewModel.statusRejected),
                      onHide: !canOverride || isHidden
                          ? null
                          : () => _moderate(review, ReviewModel.statusHidden),
                      onRestore: !canOverride || !isHidden
                          ? null
                          : () => _moderate(review, ReviewModel.statusPublished),
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
