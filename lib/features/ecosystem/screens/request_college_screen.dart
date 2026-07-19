import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/college_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/services/college_storage_service.dart';
import '../providers/ecosystem_provider.dart';

final collegeStorageServiceProvider = Provider<CollegeStorageService>((ref) {
  return CollegeStorageService();
});

class RequestCollegeScreen extends ConsumerStatefulWidget {
  const RequestCollegeScreen({super.key});

  @override
  ConsumerState<RequestCollegeScreen> createState() =>
      _RequestCollegeScreenState();
}

class _RequestCollegeScreenState extends ConsumerState<RequestCollegeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _websiteController = TextEditingController();
  final _universityController = TextEditingController();
  String? _selectedState;
  String? _photoUrl;
  bool _isSubmitting = false;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await ref.read(collegeStorageServiceProvider).uploadCollegeRequestPhoto(
            userId: user.uid,
            bytes: bytes,
            extension: file.extension ?? 'jpg',
          );
      if (mounted) setState(() => _photoUrl = url);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedState == null) return;
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add a college.')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(ecosystemServiceProvider).submitCollegeRequest(
            user: user,
            name: _nameController.text.trim(),
            city: _cityController.text.trim(),
            state: _selectedState!,
            website: _websiteController.text.trim(),
            universityName: _universityController.text.trim(),
            photoUrl: _photoUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'College submitted for admin approval. We will notify you once it is published.',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add My College')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 56, color: AppTheme.gray400),
                const SizedBox(height: 16),
                Text(
                  'Sign in to add your college',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add My College')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Can\'t find your college? Submit it for admin review. '
                'Duplicates are blocked automatically.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'College Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: const InputDecoration(labelText: 'State *'),
                items: CollegeConstants.indianStates
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedState = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'University *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website (optional)'),
              ),
              const SizedBox(height: 16),
              Text(
                'College Photo (optional)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _photoUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isUploadingPhoto ? null : _pickPhoto,
                icon: _isUploadingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_outlined),
                label: Text(_photoUrl == null ? 'Upload photo' : 'Change photo'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit for Approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
