import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../core/utils/image_optimization_utils.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../services/profile_storage_service.dart';

class PremiumProfileEditSection extends ConsumerStatefulWidget {
  final UserModel user;
  final TextEditingController branchController;
  final TextEditingController aboutController;
  final List<String> interests;
  final String availabilityStatus;
  final ValueChanged<List<String>> onInterestsChanged;
  final ValueChanged<String> onAvailabilityChanged;
  final ValueChanged<String?> onPhotoUrlChanged;
  final ValueChanged<String?> onCoverUrlChanged;

  const PremiumProfileEditSection({
    required this.user,
    required this.branchController,
    required this.aboutController,
    required this.interests,
    required this.availabilityStatus,
    required this.onInterestsChanged,
    required this.onAvailabilityChanged,
    required this.onPhotoUrlChanged,
    required this.onCoverUrlChanged,
    super.key,
  });

  @override
  ConsumerState<PremiumProfileEditSection> createState() =>
      _PremiumProfileEditSectionState();
}

class _PremiumProfileEditSectionState
    extends ConsumerState<PremiumProfileEditSection> {
  final _storage = ProfileStorageService();
  bool _isUploading = false;

  /// Reject obviously oversized sources before we hand them to the on-device
  /// codec in [ImageOptimizationUtils]. Decoding + re-encoding a 40MP camera
  /// shot on the raster thread is what made the screen hitch; capping the
  /// input keeps the worst case bounded.
  static const int _maxSourceBytes = 20 * 1024 * 1024; // 20 MB

  Future<void> _pickImage({required bool isCover}) async {
    if (_isUploading) return;

    // 1. Open the picker in its own guarded await. file_picker routes through
    //    the Android photo picker / Storage Access Framework and iOS PHPicker,
    //    none of which need a runtime storage permission (READ_MEDIA_IMAGES /
    //    READ_EXTERNAL_STORAGE), which is why the manifest declares none. The
    //    only things that can go wrong here are the user cancelling or a
    //    platform-channel error; previously an error thrown here escaped as an
    //    unhandled async exception and the screen just sat there.
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } on PlatformException catch (e, st) {
      _logImageFailure('picker open', e, st);
      _showError('Could not open the image picker. Please try again.');
      return;
    } catch (e, st) {
      _logImageFailure('picker open', e, st);
      _showError('Could not open the image picker. Please try again.');
      return;
    }

    if (!mounted) return;
    if (result == null || result.files.isEmpty) return; // user cancelled

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showError('That file could not be read. Please pick another photo.');
      return;
    }
    if (bytes.lengthInBytes > _maxSourceBytes) {
      _showError('That image is too large. Please choose one under 20 MB.');
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 2. Compress / convert + upload. optimizeForUpload runs the platform
      //    image codec and can throw (unsupported/corrupt bytes, or still over
      //    the size cap after downscaling); putData can throw on network or
      //    permission errors. All of it stays inside this try so a failure
      //    surfaces a message and a Crashlytics report instead of freezing.
      final ext = file.extension ?? 'jpg';
      final url = isCover
          ? await _storage.uploadCoverPhoto(
              userId: widget.user.uid,
              bytes: bytes,
              extension: ext,
            )
          : await _storage.uploadProfilePhoto(
              userId: widget.user.uid,
              bytes: bytes,
              extension: ext,
            );
      if (!mounted) return;
      if (isCover) {
        widget.onCoverUrlChanged(url);
      } else {
        widget.onPhotoUrlChanged(url);
      }
    } catch (e, st) {
      _logImageFailure(
        isCover ? 'cover upload' : 'avatar upload',
        e,
        st,
      );
      _showError(_friendlyImageError(e));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _logImageFailure(String stage, Object error, StackTrace stackTrace) {
    debugPrint('[PremiumProfileEditSection] $stage failed: $error');
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    CrashlyticsService.recordError(
      error,
      stackTrace,
      reason: 'profile image $stage',
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    SnackBarHelper.showErrorSnackBar(context, message: message);
  }

  String _friendlyImageError(Object error) {
    // Messages on ImageOptimizationException are already written for users.
    if (error is ImageOptimizationException) return error.message;

    final text = error.toString().toLowerCase();
    if (text.contains('too large')) {
      return 'That photo is still too large after compression. Try a smaller one.';
    }
    if (text.contains('codec') ||
        text.contains('decode') ||
        text.contains('image header')) {
      return "That file doesn't look like a valid image. Please pick another.";
    }
    if (text.contains('network') ||
        text.contains('unreachable') ||
        text.contains('timeout')) {
      return 'Upload failed — check your connection and try again.';
    }
    return 'Could not update that photo. Please try again.';
  }

  void _toggleInterest(String interest) {
    final updated = List<String>.from(widget.interests);
    if (updated.contains(interest)) {
      updated.remove(interest);
    } else if (updated.length < 8) {
      updated.add(interest);
    }
    widget.onInterestsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Premium Profile',
            subtitle: 'Photos, branch, and how others find you',
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isUploading ? null : () => _pickImage(isCover: false),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Profile Photo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isUploading ? null : () => _pickImage(isCover: true),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Cover Photo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.branchController,
            decoration: const InputDecoration(
              labelText: 'Branch',
              hintText: 'e.g. Computer Science',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.aboutController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'About Me',
              hintText: 'Tell students about yourself...',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Availability',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ProfileConstants.availabilityOptions.map((option) {
              final selected = widget.availabilityStatus == option['id'];
              return ChoiceChip(
                label: Text(option['label']!),
                selected: selected,
                onSelected: (_) => widget.onAvailabilityChanged(option['id']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Interests (up to 8)',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProfileConstants.suggestedInterests.map((interest) {
              final selected = widget.interests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: selected,
                onSelected: (_) => _toggleInterest(interest),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
