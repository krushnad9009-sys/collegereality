import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../models/review_model.dart';
import '../providers/review_provider.dart';
import '../services/firestore_review_service.dart';
import '../widgets/star_rating_widget.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const WriteReviewScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _prosController = TextEditingController();
  final _consController = TextEditingController();
  final _courseController = TextEditingController();
  int? _batchYear;
  final Map<String, double> _ratings = RatingParameters.emptyRatings();
  bool _isSubmitting = false;
  ReviewModel? _existingReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingReview());
  }

  @override
  void dispose() {
    _textController.dispose();
    _prosController.dispose();
    _consController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final review = await ref.read(reviewRepositoryProvider).getUserReviewForCollege(
          user.uid,
          widget.collegeId,
        );

    if (review != null && mounted) {
      setState(() {
        _existingReview = review;
        _textController.text = review.textReview;
        _prosController.text = review.pros.join(', ');
        _consController.text = review.cons.join(', ');
        _courseController.text = review.course ?? '';
        _batchYear = review.batchYear;
        _ratings.addAll(review.ratings);
      });
      return;
    }

    final userDetail = await ref.read(userRepositoryProvider).getUser(user.uid);
    if (userDetail != null && mounted) {
      setState(() {
        _courseController.text = userDetail.course ?? '';
        _batchYear = userDetail.batchYear;
      });
    }
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final unrated = RatingParameters.allKeys.where((k) => (_ratings[k] ?? 0) == 0);
    if (unrated.isNotEmpty) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Please rate all categories before submitting.',
      );
      return;
    }

    if (_textController.text.trim().length < 20) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Review must be at least 20 characters.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userDetail = await ref.read(userRepositoryProvider).getUser(user.uid);
      final isVerified = user.emailVerified;

      final review = ReviewModel(
        id: _existingReview?.id ?? '',
        collegeId: widget.collegeId.trim(),
        collegeName: widget.collegeName,
        userId: user.uid,
        anonymousAlias: generateAnonymousAlias(user.uid),
        course: _courseController.text.trim().isEmpty
            ? userDetail?.course
            : _courseController.text.trim(),
        batchYear: _batchYear ?? userDetail?.batchYear,
        ratings: Map.from(_ratings),
        textReview: _textController.text.trim(),
        pros: _prosController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        cons: _consController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        isVerifiedStudent: isVerified,
        status: ReviewModel.statusPublished,
        createdAt: _existingReview?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(reviewRepositoryProvider);
      late ReviewModel savedReview;
      if (_existingReview != null) {
        savedReview = review.copyWith(id: _existingReview!.id);
        await repository.updateReview(savedReview);
      } else {
        savedReview = await repository.submitReview(review);
      }

      ref
          .read(optimisticReviewsProvider.notifier)
          .addReview(widget.collegeId.trim(), savedReview);
      ref.invalidate(collegeByIdProvider(widget.collegeId.trim()));
      ref.invalidate(userReviewsProvider);

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: _existingReview != null
              ? 'Review updated successfully!'
              : 'Review submitted successfully!',
        );
        context.go(
          RouteNames.collegeDetailsPath(widget.collegeId, tab: 'reviews'),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingReview != null ? 'Edit Review' : 'Write Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () =>
              context.go(RouteNames.collegeDetailsPath(widget.collegeId)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.collegeName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your review will be posted anonymously as a verified student alias.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 24),
            ...RatingParameters.categories.expand((category) {
              return [
                Text(
                  category.label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...category.parameters.map(
                  (param) => RatingInputRow(
                    label: param.label,
                    value: _ratings[param.key] ?? 0,
                    onChanged: (v) =>
                        setState(() => _ratings[param.key] = v),
                  ),
                ),
                const SizedBox(height: 16),
              ];
            }),
            CustomTextField(
              label: 'Course',
              hint: 'e.g. B.Tech CSE',
              controller: _courseController,
              prefixIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 16),
            YearPickerField(
              label: 'Batch Year',
              value: _batchYear,
              onChanged: (year) => setState(() => _batchYear = year),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Your Review',
              hint: 'Share your honest experience (min 20 characters)...',
              controller: _textController,
              maxLines: 5,
              prefixIcon: Icons.rate_review_outlined,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Pros (comma separated)',
              hint: 'Good faculty, Great placements',
              controller: _prosController,
              prefixIcon: Icons.thumb_up_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Cons (comma separated)',
              hint: 'Strict attendance, Old hostel',
              controller: _consController,
              prefixIcon: Icons.thumb_down_outlined,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: _existingReview != null ? 'Update Review' : 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
