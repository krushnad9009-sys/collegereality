import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../models/verification_request_model.dart';
import '../providers/verification_provider.dart';
import '../services/verification_firestore_service.dart';

enum _ProofStatus { none, pending, verified, rejected }

_ProofStatus _statusFor(UserModel user) {
  final status = user.verificationStatus;
  if (status == VerificationConstants.statusApproved &&
      user.verificationBadge != VerificationConstants.badgeNone) {
    return _ProofStatus.verified;
  }
  if (status == VerificationConstants.statusPendingReview ||
      status == VerificationConstants.statusFlagged) {
    return _ProofStatus.pending;
  }
  if (status == VerificationConstants.statusRejected ||
      status == VerificationConstants.statusResubmissionRequested) {
    return _ProofStatus.rejected;
  }
  return _ProofStatus.none;
}

class _PickedProof {
  final Uint8List bytes;
  final String name;
  const _PickedProof(this.bytes, this.name);

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  bool get isImage => extension == 'jpg' || extension == 'jpeg' || extension == 'png';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// "Student Verification Documents" section of the Edit Profile screen,
/// directly below Phone Verification: pick a proof type, attach a PDF/JPG/PNG
/// (max 5 MB), upload it, and follow its review status.
///
/// Uploads go through [VerificationFirestoreService.submitDocument]: the file
/// lands in `verification_documents/{uid}/{docType}_{requestId}_{name}`, a
/// `verification_requests` doc is created, and `users/{uid}.verificationStatus`
/// becomes `pending_review`. The AI verification agent / an admin then decides;
/// the client can never mark itself verified (firestore.rules).
class StudentVerificationDocumentsSection extends ConsumerStatefulWidget {
  final UserModel user;

  /// The screen's live phone state (a number verified moments ago may not have
  /// reached [user] yet).
  final bool isPhoneVerified;

  /// The college currently selected in Academic Details (unsaved form state).
  final String? collegeId;
  final String? collegeName;

  const StudentVerificationDocumentsSection({
    required this.user,
    required this.isPhoneVerified,
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<StudentVerificationDocumentsSection> createState() =>
      _StudentVerificationDocumentsSectionState();
}

class _StudentVerificationDocumentsSectionState
    extends ConsumerState<StudentVerificationDocumentsSection> {
  String? _docType;
  _PickedProof? _picked;
  bool _isUploading = false;

  bool get _hasCollege =>
      (widget.collegeId?.trim().isNotEmpty ?? false) &&
      (widget.collegeName?.trim().isNotEmpty ?? false);

  bool get _canSubmit =>
      !_isUploading && _docType != null && _picked != null && _hasCollege;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: VerificationConstants.allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showError('Could not read that file. Please try another one.');
        return;
      }
      if (bytes.length > VerificationConstants.maxBadgeProofBytes) {
        _showError(
          'That file is ${_formatBytes(bytes.length)}. The maximum size is 5 MB.',
        );
        return;
      }
      if (!mounted) return;
      setState(() => _picked = _PickedProof(bytes, file.name));
    } catch (_) {
      _showError('Could not open the file picker. Please try again.');
    }
  }

  Future<void> _upload() async {
    final picked = _picked;
    final docType = _docType;
    if (picked == null || docType == null || !_hasCollege) return;

    setState(() => _isUploading = true);
    try {
      await ref.read(verificationServiceProvider).submitDocument(
            user: widget.user.copyWith(isPhoneVerified: widget.isPhoneVerified),
            documentType: docType,
            verificationRole: VerificationConstants.roleStudent,
            collegeId: widget.collegeId!,
            collegeName: widget.collegeName!,
            bytes: picked.bytes,
            fileName: picked.name,
          );

      ref.invalidate(currentUserDetailProvider);
      ref.invalidate(userVerificationRequestProvider(widget.user.uid));

      if (!mounted) return;
      setState(() {
        _picked = null;
        _docType = null;
      });
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Document uploaded. It is now pending review.',
      );
    } on VerificationException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not upload your document. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    SnackBarHelper.showErrorSnackBar(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = widget.user;
    final status = _statusFor(user);
    final request = ref.watch(userVerificationRequestProvider(user.uid)).valueOrNull;
    final prereqMet = user.isEmailVerified && widget.isPhoneVerified;
    final canUpload =
        status == _ProofStatus.none || status == _ProofStatus.rejected;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Student Verification Documents',
            subtitle:
                'Upload valid student proofs for badge verification '
                '(Marksheet, College ID, or APAAR ID).',
          ),
          if (status != _ProofStatus.none) ...[
            const SizedBox(height: 12),
            _SubmittedDocumentCard(status: status, request: request),
          ],
          if (canUpload) ...[
            const SizedBox(height: 16),
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
              _buildUploadForm(context, isReupload: status == _ProofStatus.rejected),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadForm(BuildContext context, {required bool isReupload}) {
    final tokens = context.tokens;
    final picked = _picked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isReupload) ...[
          Text(
            'Upload a new document',
            style: AppFonts.plusJakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<String>(
          initialValue: _docType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Document type',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          hint: const Text('Select a document type'),
          items: [
            for (final doc in VerificationConstants.badgeProofDocumentTypes)
              DropdownMenuItem(value: doc['id'], child: Text(doc['label']!)),
          ],
          onChanged: _isUploading ? null : (v) => setState(() => _docType = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 15, color: tokens.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Allowed formats: PDF, JPG, PNG · Max size: 5 MB',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (picked == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: const Text('Choose file'),
            ),
          )
        else
          _SelectedFileCard(
            file: picked,
            onRemove: _isUploading ? null : () => setState(() => _picked = null),
          ),
        if (!_hasCollege) ...[
          const SizedBox(height: 10),
          Text(
            'Select your college in Academic Details below before uploading.',
            style: AppFonts.plusJakarta(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.warningColor,
            ),
          ),
        ],
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Upload for Verification',
          isLoading: _isUploading,
          onPressed: _canSubmit ? _upload : null,
        ),
      ],
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  final _PickedProof file;
  final VoidCallback? onRemove;

  const _SelectedFileCard({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: file.isImage
                  ? Image.memory(
                      file.bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fileIcon(primary),
                    )
                  : _fileIcon(primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${file.extension.toUpperCase()} · ${_formatBytes(file.bytes.length)}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _fileIcon(Color color) => Container(
        color: color.withValues(alpha: 0.1),
        child: Icon(
          file.extension == 'pdf'
              ? Icons.picture_as_pdf_outlined
              : Icons.insert_drive_file_outlined,
          color: color,
        ),
      );
}

class _SubmittedDocumentCard extends StatelessWidget {
  final _ProofStatus status;
  final VerificationRequestModel? request;

  const _SubmittedDocumentCard({required this.status, required this.request});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final (label, icon, color) = switch (status) {
      _ProofStatus.verified => (
          'Verified',
          Icons.verified_rounded,
          AppTheme.accentColor,
        ),
      _ProofStatus.rejected => (
          'Rejected',
          Icons.cancel_outlined,
          AppTheme.errorColor,
        ),
      _ => (
          'Uploaded - Pending Review',
          Icons.hourglass_bottom_rounded,
          AppTheme.warningColor,
        ),
    };

    final docLabel = request == null
        ? 'Verification document'
        : VerificationConstants.documentLabel(request!.documentType);
    final path = request?.storagePath ?? '';
    final ext = path.contains('.') ? path.split('.').last.toUpperCase() : '';
    final reason = status == _ProofStatus.rejected ? request?.adminNote?.trim() : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ext == 'PDF'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.plusJakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (request != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (ext.isNotEmpty) ext,
                          'Submitted ${_formatDate(request!.createdAt)}',
                        ].join(' · '),
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatusBadge(label: label, icon: icon, color: color),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                color: tokens.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
