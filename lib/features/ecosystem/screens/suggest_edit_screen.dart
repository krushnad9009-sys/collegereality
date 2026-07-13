import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/ecosystem_provider.dart';

class SuggestEditScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const SuggestEditScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<SuggestEditScreen> createState() => _SuggestEditScreenState();
}

class _SuggestEditScreenState extends ConsumerState<SuggestEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  String _field = 'address';
  bool _isSubmitting = false;

  static const _fields = [
    ('address', 'Address'),
    ('website', 'Website'),
    ('phone', 'Phone'),
    ('email', 'Email'),
    ('city', 'City'),
    ('fees.tuitionMin', 'Tuition Min'),
    ('fees.tuitionMax', 'Tuition Max'),
  ];

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    final college = await ref.read(collegeRepositoryProvider).getCollegeById(widget.collegeId);
    if (user == null || college == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(ecosystemServiceProvider).submitEditSuggestion(
            user: user,
            college: college,
            field: _field,
            suggestedValue: _valueController.text.trim(),
            reason: _reasonController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit suggestion submitted.')),
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
      appBar: AppBar(title: Text('Suggest Edit — ${widget.collegeName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _field,
                decoration: const InputDecoration(labelText: 'Field to edit'),
                items: _fields
                    .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _field = v ?? _field),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Suggested value *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Submit Suggestion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
