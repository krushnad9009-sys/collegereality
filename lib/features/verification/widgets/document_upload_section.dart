import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/widgets/college_autocomplete_field.dart';
import '../providers/verification_provider.dart';
import '../services/verification_firestore_service.dart';
import 'verification_badge_widget.dart';

class DocumentUploadSection extends ConsumerStatefulWidget {
  final UserModel user;

  const DocumentUploadSection({required this.user, super.key});

  @override
  ConsumerState<DocumentUploadSection> createState() =>
      _DocumentUploadSectionState();
}

class _DocumentUploadSectionState extends ConsumerState<DocumentUploadSection> {
  String _verificationRole = VerificationConstants.roleStudent;
  String? _documentType;
  String? _collegeId;
  String? _collegeName;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _collegeId = widget.user.collegeId;
    _collegeName = widget.user.collegeName;
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: VerificationConstants.allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() {
      _fileBytes = bytes;
      _fileName = file.name;
    });
  }

  Future<void> _submit() async {
    if (_collegeId == null ||
        _collegeName == null ||
        _collegeId!.isEmpty ||
        _collegeName!.isEmpty) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Select your college.',
      );
      return;
    }

    if (_documentType == null || _fileBytes == null || _fileName == null) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Select a document type and upload one file.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(verificationServiceProvider).submitDocument(
            user: widget.user,
            documentType: _documentType!,
            verificationRole: _verificationRole,
            collegeId: _collegeId!,
            collegeName: _collegeName!,
            bytes: _fileBytes!,
            fileName: _fileName!,
          );
      ref.invalidate(currentUserDetailProvider);
      ref.invalidate(userVerificationRequestProvider(widget.user.uid));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Verification submitted. An admin will review your document.',
        );
        setState(() {
          _fileBytes = null;
          _fileName = null;
          _documentType = null;
        });
      }
    } on VerificationException catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
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
    final user = widget.user;
    final hasBadge = user.verificationBadge != VerificationConstants.badgeNone;
    final requestAsync =
        ref.watch(userVerificationRequestProvider(user.uid));

    if (hasBadge) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Complete',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          VerificationBadgeWidget(badge: user.verificationBadge),
          const SizedBox(height: 8),
          Text(
            'You can write reviews, answer student questions, and participate in the community.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600),
          ),
        ],
      );
    }

    final emailDone = user.isEmailVerified;
    final phoneDone = user.isPhoneVerified;
    final canUpload = emailDone && phoneDone;
    final documentOptions =
        VerificationConstants.documentTypesForRole(_verificationRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register as',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: VerificationConstants.roleStudent,
              label: Text('Current Student'),
              icon: Icon(Icons.school_outlined),
            ),
            ButtonSegment(
              value: VerificationConstants.roleAlumni,
              label: Text('Alumni'),
              icon: Icon(Icons.workspace_premium_outlined),
            ),
          ],
          selected: {_verificationRole},
          onSelectionChanged: canUpload &&
                  user.verificationStatus !=
                      VerificationConstants.statusPendingReview &&
                  user.verificationStatus != VerificationConstants.statusFlagged
              ? (selected) {
                  if (selected.isEmpty) return;
                  setState(() {
                    _verificationRole = selected.first;
                    _documentType = null;
                  });
                }
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          'Verification steps',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _verificationRole == VerificationConstants.roleAlumni
              ? 'Upload graduation marksheet or bonafide certificate.'
              : 'Upload college ID card or bonafide certificate.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
        ),
        const SizedBox(height: 12),
        _StepRow(
          label: 'Email verified',
          done: emailDone,
          icon: Icons.email_outlined,
        ),
        _StepRow(
          label: 'Mobile OTP verified',
          done: phoneDone,
          icon: Icons.phone_android_outlined,
        ),
        _StepRow(
          label: 'Document submitted & approved',
          done: user.verificationStatus == VerificationConstants.statusApproved,
          icon: Icons.upload_file_outlined,
        ),
        requestAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (request) {
            if (request == null) return const SizedBox.shrink();

            if (request.status == VerificationConstants.statusPendingReview ||
                request.status == VerificationConstants.statusFlagged) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.status == VerificationConstants.statusFlagged
                          ? 'Flagged for admin review'
                          : 'Under admin review',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.aiSummary,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.gray700,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (request.status == VerificationConstants.statusRejected ||
                request.status ==
                    VerificationConstants.statusResubmissionRequested) {
              final isResubmit = request.status ==
                  VerificationConstants.statusResubmissionRequested;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isResubmit
                          ? 'Admin requested a new document'
                          : 'Verification rejected',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    if (request.adminNote != null &&
                        request.adminNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        request.adminNote!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.gray700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Upload a clearer document below to try again.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        if (canUpload &&
            user.verificationStatus != VerificationConstants.statusPendingReview &&
            user.verificationStatus != VerificationConstants.statusFlagged) ...[
          const SizedBox(height: 16),
          Text(
            'Your college',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: InputDecoration(
              labelText: 'Document type',
              filled: true,
              fillColor: AppTheme.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: documentOptions
                .map(
                  (d) => DropdownMenuItem(
                    value: d['id'],
                    child: Text(d['label']!),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _documentType = value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName ?? 'Upload document (photo/PDF)'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Submit for Verification',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ] else if (!canUpload) ...[
          const SizedBox(height: 12),
          Text(
            'Complete email and mobile verification above to upload your document.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done;
  final IconData icon;

  const _StepRow({
    required this.label,
    required this.done,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : icon,
            size: 20,
            color: done ? AppTheme.accentColor : AppTheme.gray500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: done ? AppTheme.gray800 : AppTheme.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
