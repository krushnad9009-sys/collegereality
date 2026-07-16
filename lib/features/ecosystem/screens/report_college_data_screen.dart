import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/ecosystem_constants.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/ecosystem_provider.dart';

class ReportCollegeDataScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const ReportCollegeDataScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<ReportCollegeDataScreen> createState() =>
      _ReportCollegeDataScreenState();
}

class _ReportCollegeDataScreenState extends ConsumerState<ReportCollegeDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _reportType = EcosystemConstants.reportWrongFees;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    final college = await ref.read(collegeRepositoryProvider).getCollegeById(widget.collegeId);
    if (user == null || college == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(ecosystemServiceProvider).submitDataReport(
            user: user,
            college: college,
            reportType: _reportType,
            description: _descriptionController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
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
      appBar: AppBar(title: Text('Report — ${widget.collegeName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _reportType,
                decoration: const InputDecoration(labelText: 'Issue type'),
                items: EcosystemConstants.dataReportTypes
                    .map((t) => DropdownMenuItem(
                          value: t['id'],
                          child: Text(t['label']!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _reportType = v ?? _reportType),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Details *',
                  hintText: 'Describe what is wrong',
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
