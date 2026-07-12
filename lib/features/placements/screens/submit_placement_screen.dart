import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/placement_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/placement_submission_model.dart';
import '../providers/placement_provider.dart';

class SubmitPlacementScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const SubmitPlacementScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<SubmitPlacementScreen> createState() =>
      _SubmitPlacementScreenState();
}

class _SubmitPlacementScreenState extends ConsumerState<SubmitPlacementScreen> {
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _packageController = TextEditingController();
  final _branchController = TextEditingController();
  String _employmentType = PlacementConstants.typeFullTime;
  int _year = DateTime.now().year;
  Uint8List? _offerBytes;
  String? _offerExtension;
  String? _offerFileName;
  bool _submitting = false;

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _packageController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _pickOfferLetter() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: PlacementConstants.allowedOfferExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.bytes!.length > PlacementConstants.maxOfferLetterBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File must be under 10 MB')),
        );
      }
      return;
    }
    setState(() {
      _offerBytes = file.bytes;
      _offerExtension = file.extension?.toLowerCase();
      _offerFileName = file.name;
    });
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final company = _companyController.text.trim();
    final role = _roleController.text.trim();
    final package = double.tryParse(_packageController.text.trim());

    if (company.length < PlacementConstants.minCompanyNameLength) {
      _showError('Enter a valid company name.');
      return;
    }
    if (role.length < PlacementConstants.minRoleLength) {
      _showError('Enter a valid job role.');
      return;
    }
    if (package == null ||
        package < PlacementConstants.minPackageLpa ||
        package > PlacementConstants.maxPackageLpa) {
      _showError('Enter a valid package in LPA (0.1 – 200).');
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(placementRepositoryProvider);
      final submission = PlacementSubmissionModel(
        id: '',
        collegeId: widget.collegeId,
        collegeName: widget.collegeName,
        userId: user.uid,
        companyName: company,
        jobRole: role,
        packageLpa: package,
        employmentType: _employmentType,
        year: _year,
        branch: _branchController.text.trim().isEmpty
            ? null
            : _branchController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repo.createSubmission(submission: submission);

      if (_offerBytes != null && _offerExtension != null) {
        final path = await repo.uploadOfferLetter(
          userId: user.uid,
          submissionId: created.id,
          extension: _offerExtension!,
          bytes: _offerBytes!,
        );
        await repo.attachOfferLetter(
          submissionId: created.id,
          offerLetterStoragePath: path,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Submitted for admin review. Offer letter is private until approved.',
            ),
          ),
        );
        context.go(
          RouteNames.collegeDetailsPath(widget.collegeId, tab: 'placements'),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifiedAsync = ref.watch(isVerifiedForPlacementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Placement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: verifiedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (isVerified) {
          if (!isVerified) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Profile verification required',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only verified students can submit placement details.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppTheme.gray500),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(RouteNames.verification),
                      child: const Text('Get Verified'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.collegeName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submissions require admin approval before appearing publicly. '
                  'Offer letters are never shown to other students.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.gray500,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Role *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _packageController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Package (LPA) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _employmentType,
                  decoration: const InputDecoration(
                    labelText: 'Internship or Full-time *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PlacementConstants.typeFullTime,
                      child: Text('Full-time'),
                    ),
                    DropdownMenuItem(
                      value: PlacementConstants.typeInternship,
                      child: Text('Internship'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _employmentType = v);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(
                    labelText: 'Year *',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(6, (i) {
                    final y = DateTime.now().year - i;
                    return DropdownMenuItem(value: y, child: Text('$y'));
                  }),
                  onChanged: (v) {
                    if (v != null) setState(() => _year = v);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _branchController,
                  decoration: const InputDecoration(
                    labelText: 'Branch / Course (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickOfferLetter,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _offerFileName ?? 'Upload Offer Letter (optional, private)',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Submit for Admin Review',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
