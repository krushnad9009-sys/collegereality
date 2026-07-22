import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/constants/review_constants.dart';
import '../../../core/constants/review_verification.dart';
import '../../../core/constants/review_yes_no_questions.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../models/review_model.dart';
import '../providers/review_provider.dart';
import '../services/review_storage_service.dart';
import '../widgets/star_rating_widget.dart';

final reviewStorageServiceProvider = Provider<ReviewStorageService>((ref) {
  return ReviewStorageService();
});

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
  bool _isUploadingMedia = false;
  ReviewModel? _existingReview;
  List<String> _photoUrls = [];
  List<String> _videoUrls = [];
  final Map<String, bool?> _yesNoAnswers = ReviewYesNoQuestions.emptyAnswers();

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

  void _mapLegacyYesNoAnswers(Map<String, bool> answers) {
    if (_yesNoAnswers[ReviewYesNoQuestions.wouldChooseAgain] == null) {
      if (answers['wouldTakeAdmissionAgain'] != null) {
        _yesNoAnswers[ReviewYesNoQuestions.wouldChooseAgain] =
            answers['wouldTakeAdmissionAgain'];
      } else if (answers['wouldRecommend'] != null) {
        _yesNoAnswers[ReviewYesNoQuestions.wouldChooseAgain] =
            answers['wouldRecommend'];
      }
    }
    if (_yesNoAnswers[ReviewYesNoQuestions.placementSupport] == null &&
        answers['placementsAsPromised'] != null) {
      _yesNoAnswers[ReviewYesNoQuestions.placementSupport] =
          answers['placementsAsPromised'];
    }
    if (_yesNoAnswers[ReviewYesNoQuestions.raggingPresent] == null &&
        answers['raggingPresent'] != null) {
      _yesNoAnswers[ReviewYesNoQuestions.raggingPresent] =
          answers['raggingPresent'];
    }
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
        _photoUrls = List.from(review.photoUrls);
        _videoUrls = List.from(review.videoUrls);
        _ratings.addAll(review.ratings);
        if ((_ratings[RatingParameters.fees] ?? 0) == 0 &&
            review.ratings.containsKey(RatingParameters.feesValue)) {
          _ratings[RatingParameters.fees] =
              review.ratings[RatingParameters.feesValue]!;
        }
        for (final q in ReviewYesNoQuestions.questions) {
          if (review.yesNoAnswers.containsKey(q.key)) {
            _yesNoAnswers[q.key] = review.yesNoAnswers[q.key];
          }
        }
        _mapLegacyYesNoAnswers(review.yesNoAnswers);
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

  Future<void> _pickPhotos() async {
    if (_photoUrls.length >= ReviewConstants.maxPhotos) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    if (result == null) return;

    setState(() => _isUploadingMedia = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final storage = ref.read(reviewStorageServiceProvider);
      final reviewId = _existingReview?.id ?? 'draft_${user.uid}';

      for (final file in result.files) {
        if (_photoUrls.length >= ReviewConstants.maxPhotos) break;
        final bytes = file.bytes;
        if (bytes == null) continue;
        final url = await storage.uploadPhoto(
          userId: user.uid,
          reviewId: reviewId,
          bytes: bytes,
          extension: file.extension ?? 'jpg',
        );
        _photoUrls.add(url);
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_videoUrls.length >= ReviewConstants.maxVideos) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _isUploadingMedia = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final storage = ref.read(reviewStorageServiceProvider);
      final reviewId = _existingReview?.id ?? 'draft_${user.uid}';
      final url = await storage.uploadVideo(
        userId: user.uid,
        reviewId: reviewId,
        bytes: bytes,
        extension: file.extension ?? 'mp4',
      );
      _videoUrls.add(url);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final userDetail = await ref.read(userRepositoryProvider).getUser(user.uid);
    if (!mounted) return;
    if (userDetail == null || !canSubmitCollegeReview(userDetail)) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Only verified students or alumni can write reviews.',
      );
      return;
    }

    if (_existingReview != null && !_existingReview!.canEditAgain) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message:
            'You can edit your review again in ${_existingReview!.daysUntilEditAllowed} day(s).',
      );
      return;
    }

    final unanswered = ReviewYesNoQuestions.questions
        .where((q) => _yesNoAnswers[q.key] == null)
        .toList();
    if (unanswered.isNotEmpty) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Please answer all yes/no questions.',
      );
      return;
    }

    final unrated = RatingParameters.allKeys.where((k) => (_ratings[k] ?? 0) == 0);
    if (unrated.isNotEmpty) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Please rate all categories before submitting.',
      );
      return;
    }

    if (_textController.text.trim().length < ReviewConstants.minTextLength) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Review must be at least ${ReviewConstants.minTextLength} characters.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final yesNoAnswers = {
        for (final q in ReviewYesNoQuestions.questions)
          q.key: _yesNoAnswers[q.key]!,
      };
      final badgeLabel = reviewerBadgeLabel(userDetail);

      final review = ReviewModel(
        id: _existingReview?.id ?? '',
        collegeId: widget.collegeId.trim(),
        collegeName: widget.collegeName,
        userId: user.uid,
        anonymousAlias: userDetail.effectivePublicDisplayName,
        isAnonymous: userDetail.usesAnonymousPublicDisplayName,
        course: _courseController.text.trim().isEmpty
            ? userDetail.course
            : _courseController.text.trim(),
        batchYear: _batchYear ?? userDetail.batchYear,
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
        photoUrls: _photoUrls,
        videoUrls: _videoUrls,
        isVerifiedStudent: true,
        reviewerBadge: badgeLabel,
        yesNoAnswers: yesNoAnswers,
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
    final userDetailAsync = ref.watch(currentUserDetailProvider);

    return userDetailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (userDetail) {
        if (userDetail == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to write a review')),
          );
        }

        if (!canSubmitCollegeReview(userDetail)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Write Review'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () =>
                    context.go(RouteNames.collegeDetailsPath(widget.collegeId)),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Verified Students & Alumni Only',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete student or alumni verification to share honest, trusted reviews.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: AppTheme.gray600),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Get Verified',
                    onPressed: () => context.go(RouteNames.verification),
                  ),
                ],
              ),
            ),
          );
        }

        final editLocked =
            _existingReview != null && !_existingReview!.canEditAgain;

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
                Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Verified students & alumni only — India\'s most trusted reviews',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (editLocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'You can edit again in ${_existingReview!.daysUntilEditAllowed} day(s). '
                      'Reviews can be updated once every ${ReviewConstants.editCooldownDays} days.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.gray700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Posting as your public display name from profile settings. '
                    'Verification badge remains visible.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                        enabled: !editLocked,
                        onChanged: (v) =>
                            setState(() => _ratings[param.key] = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ];
                }),
                Text(
                  'Yes / No Questions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...ReviewYesNoQuestions.questions.map((question) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Yes')),
                            ButtonSegment(value: false, label: Text('No')),
                          ],
                          selected: _yesNoAnswers[question.key] != null
                              ? {_yesNoAnswers[question.key]!}
                              : {},
                          emptySelectionAllowed: true,
                          onSelectionChanged: editLocked
                              ? null
                              : (selected) {
                                  if (selected.isEmpty) return;
                                  setState(() {
                                    _yesNoAnswers[question.key] =
                                        selected.first;
                                  });
                                },
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
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
                  hint: 'Share your honest experience (min ${ReviewConstants.minTextLength} characters)...',
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
                const SizedBox(height: 20),
                Text(
                  'Photos & Videos',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingMedia ? null : _pickPhotos,
                        icon: const Icon(Icons.photo_outlined),
                        label: Text('Photos (${_photoUrls.length}/${ReviewConstants.maxPhotos})'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingMedia ? null : _pickVideo,
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text('Videos (${_videoUrls.length}/${ReviewConstants.maxVideos})'),
                      ),
                    ),
                  ],
                ),
                if (_isUploadingMedia)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: _existingReview != null ? 'Update Review' : 'Submit Review',
                  isLoading: _isSubmitting,
                  onPressed: editLocked ? null : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
