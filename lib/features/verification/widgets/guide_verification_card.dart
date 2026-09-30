import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/widgets/college_autocomplete_field.dart';
import '../providers/verification_provider.dart';
import '../services/verification_firestore_service.dart';
import 'guide_documents_picker.dart';

/// "Student Verification" card for the Edit Profile screen, sitting right
/// above "Guide Settings". Drives the 2-document upload flow whose approval
/// unblocks the "Available as a guide" toggle.
class GuideVerificationCard extends ConsumerWidget {
  final UserModel user;

  const GuideVerificationCard({required this.user, super.key});

  /// Opens the 2-document upload sheet. Also called from the disabled
  /// "Available as a guide" toggle so a tap there routes here instead of
  /// doing nothing.
  static Future<void> openSheet(BuildContext context, UserModel user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GuideVerificationSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    final badge = user.verificationBadge;
    final status = user.verificationStatus;
    final isApproved =
        VerificationConstants.isApprovedStudentOrAlumni(badge, status);
    final isPending = status == VerificationConstants.statusPendingReview ||
        status == VerificationConstants.statusFlagged;
    final isRejected = status == VerificationConstants.statusRejected ||
        status == VerificationConstants.statusResubmissionRequested;
    final prereqMet = user.isEmailVerified && user.isPhoneVerified;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Student Verification',
                  subtitle:
                      'Verify your student identity to become a paid guide',
                ),
              ),
              if (isApproved)
                StatusBadge(
                  label: 'Verified',
                  icon: Icons.verified,
                  color: AppTheme.accentColor,
                )
              else if (isPending)
                StatusBadge(
                  label: 'In review',
                  icon: Icons.hourglass_bottom_rounded,
                  color: AppTheme.warningColor,
                )
              else
                StatusBadge(
                  label: 'Not verified',
                  icon: Icons.error_outline_rounded,
                  color: AppTheme.warningColor,
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (isApproved)
            Text(
              'You\'re a verified ${badge == VerificationConstants.badgeVerifiedAlumni ? 'alumnus' : 'student'}. '
              'The "Available as a guide" toggle below is unlocked.',
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                color: tokens.textSecondary,
              ),
            )
          else if (isPending)
            Text(
              'Your documents are under review. You\'ll be able to turn on '
              '"Available as a guide" once an admin approves them.',
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                color: tokens.textSecondary,
              ),
            )
          else ...[
            Text(
              isRejected
                  ? 'Your last submission wasn\'t approved. Upload '
                      '${VerificationConstants.requiredGuideVerificationDocs} '
                      'clear documents to try again.'
                  : 'Upload any '
                      '${VerificationConstants.requiredGuideVerificationDocs} '
                      'of: College ID Card, Transfer Certificate (TC), '
                      'APAAR ID / Aadhaar ID, or Marksheet.',
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (!prereqMet)
              Text(
                'Verify your email and mobile number above first.',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColor,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => openSheet(context, user),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(
                    isRejected
                        ? 'Re-upload Verification Documents'
                        : 'Upload Verification Documents',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GuideVerificationSheet extends ConsumerStatefulWidget {
  final UserModel user;

  const _GuideVerificationSheet({required this.user});

  @override
  ConsumerState<_GuideVerificationSheet> createState() =>
      _GuideVerificationSheetState();
}

class _GuideVerificationSheetState
    extends ConsumerState<_GuideVerificationSheet> {
  static const _required = VerificationConstants.requiredGuideVerificationDocs;

  List<GuideVerificationDoc> _docs = const [];
  String? _collegeId;
  String? _collegeName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _collegeId = widget.user.collegeId;
    _collegeName = widget.user.collegeName;
  }

  bool get _needsCollege =>
      (_collegeId == null || _collegeId!.trim().isEmpty) ||
      (_collegeName == null || _collegeName!.trim().isEmpty);

  bool get _canSubmit =>
      !_isSubmitting && _docs.length == _required && !_needsCollege;

  Future<void> _submit() async {
    if (_docs.length != _required) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Upload a file for $_required different documents.',
      );
      return;
    }
    if (_needsCollege) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Select your college.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final docs = _docs;

      await ref.read(verificationServiceProvider).submitGuideVerificationDocuments(
            user: widget.user,
            verificationRole: VerificationConstants.roleStudent,
            collegeId: _collegeId!,
            collegeName: _collegeName!,
            documents: docs,
          );

      ref.invalidate(currentUserDetailProvider);
      ref.invalidate(userVerificationRequestProvider(widget.user.uid));

      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Documents submitted. An admin will review them shortly.',
      );
    } on VerificationException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not submit your documents. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + viewInsets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Verification Documents',
              style: AppFonts.plusJakarta(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            GuideDocumentsPicker(
              enabled: !_isSubmitting,
              onChanged: (docs) => setState(() => _docs = docs),
            ),
            if (_needsCollege) ...[
              const SizedBox(height: 8),
              Text(
                'Your college',
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CollegeAutocompleteField(
                selectedCollegeId: _collegeId,
                selectedCollegeName: _collegeName,
                onChanged: (college) {
                  setState(() {
                    _collegeId = college?.id;
                    _collegeName = college?.name;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Submit for Verification',
              isLoading: _isSubmitting,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
