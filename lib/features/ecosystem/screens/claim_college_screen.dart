import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/ecosystem_provider.dart';

class ClaimCollegeScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const ClaimCollegeScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<ClaimCollegeScreen> createState() => _ClaimCollegeScreenState();
}

class _ClaimCollegeScreenState extends ConsumerState<ClaimCollegeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  String? _authLetterUrl;
  String? _idUrl;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<String?> _upload(String folder, String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return null;
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return null;

    final file = File(result.files.single.path!);
    final refPath =
        'college_claim_documents/${widget.collegeId}/${user.uid}/$folder/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
    await FirebaseStorage.instance.ref(refPath).putFile(file);
    return FirebaseStorage.instance.ref(refPath).getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    final college = await ref.read(collegeRepositoryProvider).getCollegeById(widget.collegeId);
    if (user == null || college == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(ecosystemServiceProvider).submitCollegeClaim(
            user: user,
            college: college,
            officialEmail: _emailController.text.trim(),
            representativeName: _nameController.text.trim(),
            representativeDesignation: _designationController.text.trim(),
            authorizationLetterUrl: _authLetterUrl,
            representativeIdUrl: _idUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim submitted for admin approval.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Claim — ${widget.collegeName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Official representatives can claim this college. Admin approval required.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Official Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Valid email required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Representative Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = await _upload('authorization', 'letter');
                  if (url != null) setState(() => _authLetterUrl = url);
                },
                icon: const Icon(Icons.upload_file),
                label: Text(_authLetterUrl == null
                    ? 'Upload Authorization Letter'
                    : 'Authorization Letter uploaded'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = await _upload('id', 'id');
                  if (url != null) setState(() => _idUrl = url);
                },
                icon: const Icon(Icons.badge_outlined),
                label: Text(_idUrl == null
                    ? 'Upload Representative ID'
                    : 'ID uploaded'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Submit Claim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
