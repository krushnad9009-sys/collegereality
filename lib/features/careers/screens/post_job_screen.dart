import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/careers_constants.dart';
import '../../../core/widgets/index.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';
import '../utils/careers_filter_utils.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _eligibility = TextEditingController();
  final _description = TextEditingController();
  final _skills = TextEditingController();
  String _jobLevel = CareersConstants.jobLevelFresher;
  String _workType = CareersConstants.workTypeOffice;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _eligibility.dispose();
    _description.dispose();
    _skills.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post Job'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_title, 'Job title'),
          _field(_location, 'Location'),
          _field(_salaryMin, 'Min salary (LPA)'),
          _field(_salaryMax, 'Max salary (LPA)'),
          _field(_eligibility, 'Eligibility', maxLines: 2),
          _field(_description, 'Description', maxLines: 4),
          _field(_skills, 'Skills (comma separated)'),
          DropdownButtonFormField<String>(
            value: _jobLevel,
            decoration: const InputDecoration(labelText: 'Job level'),
            items: const [
              DropdownMenuItem(value: CareersConstants.jobLevelFresher, child: Text('Fresher')),
              DropdownMenuItem(
                  value: CareersConstants.jobLevelExperienced, child: Text('Experienced')),
            ],
            onChanged: (v) => setState(() => _jobLevel = v ?? _jobLevel),
          ),
          DropdownButtonFormField<String>(
            value: _workType,
            decoration: const InputDecoration(labelText: 'Work type'),
            items: const [
              DropdownMenuItem(value: CareersConstants.workTypeOffice, child: Text('Office')),
              DropdownMenuItem(value: CareersConstants.workTypeRemote, child: Text('Remote')),
              DropdownMenuItem(value: CareersConstants.workTypeHybrid, child: Text('Hybrid')),
            ],
            onChanged: (v) => setState(() => _workType = v ?? _workType),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish Job'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final account = ref.read(companyAccountProvider).valueOrNull;
    if (account == null || !account.isVerified) return;
    if (_title.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final id = 'job_${const Uuid().v4().substring(0, 8)}';
      final skills = _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final job = JobModel(
        id: id,
        title: _title.text.trim(),
        companyId: account.companyId,
        companyName: account.companyName,
        location: _location.text.trim(),
        jobLevel: _jobLevel,
        workType: _workType,
        salaryMinLpa: double.tryParse(_salaryMin.text) ?? 0,
        salaryMaxLpa: double.tryParse(_salaryMax.text) ?? 0,
        eligibility: _eligibility.text.trim(),
        description: _description.text.trim(),
        skills: skills,
        searchText: buildCareersSearchText([
          _title.text,
          account.companyName,
          _location.text,
          _eligibility.text,
          ...skills,
        ]),
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(careersRepositoryProvider).createJobListing(job);
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Job published');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
