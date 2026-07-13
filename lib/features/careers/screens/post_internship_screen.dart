import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/careers_constants.dart';
import '../../../core/widgets/index.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';
import '../utils/careers_filter_utils.dart';

class PostInternshipScreen extends ConsumerStatefulWidget {
  const PostInternshipScreen({super.key});

  @override
  ConsumerState<PostInternshipScreen> createState() => _PostInternshipScreenState();
}

class _PostInternshipScreenState extends ConsumerState<PostInternshipScreen> {
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _stipend = TextEditingController();
  final _duration = TextEditingController();
  final _description = TextEditingController();
  final _skills = TextEditingController();
  String _workType = CareersConstants.workTypeOffice;
  String _payType = CareersConstants.payTypePaid;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _stipend.dispose();
    _duration.dispose();
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
        title: const Text('Post Internship'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_title, 'Title'),
          _field(_city, 'City'),
          _field(_stipend, 'Stipend (e.g. ₹25,000/month)'),
          _field(_duration, 'Duration (e.g. 6 months)'),
          _field(_description, 'Description', maxLines: 4),
          _field(_skills, 'Skills (comma separated)'),
          const SizedBox(height: 12),
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
          DropdownButtonFormField<String>(
            value: _payType,
            decoration: const InputDecoration(labelText: 'Pay type'),
            items: const [
              DropdownMenuItem(value: CareersConstants.payTypePaid, child: Text('Paid')),
              DropdownMenuItem(value: CareersConstants.payTypeUnpaid, child: Text('Unpaid')),
            ],
            onChanged: (v) => setState(() => _payType = v ?? _payType),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish Internship'),
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
      final id = 'int_${const Uuid().v4().substring(0, 8)}';
      final skills = _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final internship = InternshipModel(
        id: id,
        title: _title.text.trim(),
        companyId: account.companyId,
        companyName: account.companyName,
        city: _city.text.trim(),
        payType: _payType,
        stipend: _stipend.text.trim(),
        stipendMin: int.tryParse(RegExp(r'\d+').stringMatch(_stipend.text) ?? '') ?? 0,
        duration: _duration.text.trim(),
        durationWeeks: _duration.text.toLowerCase().contains('month')
            ? (int.tryParse(RegExp(r'\d+').stringMatch(_duration.text) ?? '') ?? 0) * 4
            : int.tryParse(RegExp(r'\d+').stringMatch(_duration.text) ?? '') ?? 0,
        workType: _workType,
        description: _description.text.trim(),
        skills: skills,
        searchText: buildCareersSearchText([
          _title.text,
          account.companyName,
          _city.text,
          ...skills,
        ]),
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(careersRepositoryProvider).createInternshipListing(internship);
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Internship published');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
