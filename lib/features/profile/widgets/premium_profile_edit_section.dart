import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/profile_constants.dart';
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

  Future<void> _pickImage({required bool isCover}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _isUploading = true);
    try {
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
      if (isCover) {
        widget.onCoverUrlChanged(url);
      } else {
        widget.onPhotoUrlChanged(url);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Profile',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : () => _pickImage(isCover: false),
                icon: const Icon(Icons.person_outline),
                label: const Text('Profile Photo'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : () => _pickImage(isCover: true),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Cover Photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.branchController,
          decoration: InputDecoration(
            labelText: 'Branch',
            hintText: 'e.g. Computer Science',
            filled: true,
            fillColor: AppTheme.gray100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.aboutController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'About Me',
            hintText: 'Tell students about yourself...',
            filled: true,
            fillColor: AppTheme.gray100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Availability',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
    );
  }
}
