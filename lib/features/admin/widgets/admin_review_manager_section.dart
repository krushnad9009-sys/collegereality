import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/rating_parameters.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/widgets/index.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/star_rating_widget.dart';

/// "Manage & Add Reviews" section at the bottom of the Edit College screen
/// -- Super Admin injects a custom review directly, no student account
/// required. See FirestoreReviewService.adminCreateReview for exactly how
/// this differs from a real self-service submission.
class AdminReviewManagerSection extends StatelessWidget {
  final String collegeId;
  final String collegeName;

  const AdminReviewManagerSection({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  Future<void> _openAddReviewDialog(BuildContext context) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddCustomReviewDialog(collegeId: collegeId, collegeName: collegeName),
    );
    if (added == true && context.mounted) {
      SnackBarHelper.showSuccessSnackBar(context, message: 'Review added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage & Add Reviews',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          "Add a review on this student's behalf -- useful for seeding a new "
          'college listing or backfilling a review collected outside the app. '
          '"Verified Student" controls whether it counts toward the rating, '
          'the same as any other review.',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.gray500),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openAddReviewDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Review'),
        ),
      ],
    );
  }
}

class _AddCustomReviewDialog extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const _AddCustomReviewDialog({required this.collegeId, required this.collegeName});

  @override
  ConsumerState<_AddCustomReviewDialog> createState() => _AddCustomReviewDialogState();
}

class _AddCustomReviewDialogState extends ConsumerState<_AddCustomReviewDialog> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  double _rating = 5;
  DateTime _date = DateTime.now();
  // Defaults checked: an admin adding a review almost always wants it to
  // actually count toward the college's rating, and ReviewModel.
  // isPublicVisible (and so whether the aggregate delta applies at all)
  // requires this to be true -- leaving it unchecked silently produces a
  // review that never shows up in the public feed or rating.
  bool _isVerified = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _date.hour,
        pickedTime?.minute ?? _date.minute,
      );
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final text = _textController.text.trim();
    if (name.isEmpty) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Enter a student name');
      return;
    }
    if (_rating <= 0) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Pick a star rating');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final review = ReviewModel(
        id: '',
        collegeId: widget.collegeId,
        collegeName: widget.collegeName,
        // No real backing account -- a fresh synthetic id per review so
        // two admin-injected reviews never collide under the same "userId"
        // for any userId-keyed logic elsewhere (top-contributor tallies,
        // "your own review" lookups, etc).
        userId: 'admin_custom_${const Uuid().v4()}',
        anonymousAlias: name,
        isAnonymous: false,
        ratings: {RatingParameters.overall: _rating},
        textReview: text,
        isVerifiedStudent: _isVerified,
        reviewerBadge: _isVerified ? 'Verified Student' : null,
        status: ReviewModel.statusPublished,
        createdAt: _date,
        updatedAt: DateTime.now(),
        isAdminCreated: true,
      );
      await ref.read(reviewRepositoryProvider).adminCreateReview(review);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: FirestoreErrorUtils.userMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Review'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Rating', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              StarRatingWidget(
                rating: _rating,
                starSize: 32,
                onRatingChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Review Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time'),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year} '
                  '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: _pickDate,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Verified Student'),
                subtitle: const Text('Unchecked reviews are saved but excluded from the rating'),
                value: _isVerified,
                onChanged: (v) => setState(() => _isVerified = v ?? true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Review'),
        ),
      ],
    );
  }
}
