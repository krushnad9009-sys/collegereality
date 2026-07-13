import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/ecosystem_provider.dart';

class FacultyVerificationScreen extends ConsumerStatefulWidget {
  const FacultyVerificationScreen({super.key});

  @override
  ConsumerState<FacultyVerificationScreen> createState() =>
      _FacultyVerificationScreenState();
}

class _FacultyVerificationScreenState
    extends ConsumerState<FacultyVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  String? _facultyIdUrl;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _uploadId() async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final path =
        'faculty_documents/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
    await FirebaseStorage.instance.ref(path).putFile(file);
    final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
    setState(() => _facultyIdUrl = url);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null || user.collegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set your college in profile first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(ecosystemServiceProvider).submitFacultyVerification(
            user: user,
            collegeId: user.collegeId!,
            collegeName: user.collegeName ?? '',
            officialEmail: _emailController.text.trim(),
            department: _departmentController.text.trim(),
            designation: _designationController.text.trim(),
            facultyIdUrl: _facultyIdUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty verification submitted.')),
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
      appBar: AppBar(title: const Text('Faculty Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verified faculty can answer questions, publish workshops and research. Faculty cannot modify reviews or ratings.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Official Email *'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Valid email required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _uploadId,
                icon: const Icon(Icons.badge_outlined),
                label: Text(_facultyIdUrl == null ? 'Upload Faculty ID' : 'ID uploaded'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Submit for Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
