import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../colleges/utils/college_search_utils.dart';

class AdminCollegeEditScreen extends ConsumerStatefulWidget {
  final String? collegeId;

  const AdminCollegeEditScreen({this.collegeId, super.key});

  @override
  ConsumerState<AdminCollegeEditScreen> createState() =>
      _AdminCollegeEditScreenState();
}

class _AdminCollegeEditScreenState extends ConsumerState<AdminCollegeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _universityController;
  late final TextEditingController _tuitionMinController;
  late final TextEditingController _tuitionMaxController;
  late final TextEditingController _hostelFeeController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _mapsUrlController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _coursesController;
  late final TextEditingController _naacGradeController;
  late final TextEditingController _nirfRankController;
  late final TextEditingController _placementHighController;
  late final TextEditingController _placementAvgController;
  late final TextEditingController _placementPctController;

  String _state = CollegeConstants.indianStates.first;
  String _type = CollegeConstants.collegeTypes.first;
  bool _ugc = false;
  bool _aicte = false;
  bool _isActive = true;
  bool _isSaving = false;
  CollegeModel? _existing;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _universityController = TextEditingController();
    _tuitionMinController = TextEditingController();
    _tuitionMaxController = TextEditingController();
    _hostelFeeController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _mapsUrlController = TextEditingController();
    _logoUrlController = TextEditingController();
    _coverUrlController = TextEditingController();
    _coursesController = TextEditingController();
    _naacGradeController = TextEditingController();
    _nirfRankController = TextEditingController();
    _placementHighController = TextEditingController();
    _placementAvgController = TextEditingController();
    _placementPctController = TextEditingController();

    if (widget.collegeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCollege());
    }
  }

  Future<void> _loadCollege() async {
    final college =
        await ref.read(collegeRepositoryProvider).getCollegeById(widget.collegeId!);
    if (college == null || !mounted) return;
    setState(() {
      _existing = college;
      _nameController.text = college.name;
      _cityController.text = college.city;
      _state = college.state;
      _type = college.type;
      _addressController.text = college.address;
      _websiteController.text = college.website ?? '';
      _universityController.text = college.universityName ?? '';
      _tuitionMinController.text = '${college.fees.tuitionMin}';
      _tuitionMaxController.text = '${college.fees.tuitionMax}';
      _hostelFeeController.text = '${college.fees.hostelAnnual}';
      _latController.text = college.latitude?.toString() ?? '';
      _lngController.text = college.longitude?.toString() ?? '';
      _mapsUrlController.text = college.googleMapsUrl ?? '';
      _logoUrlController.text = college.logoUrl ?? '';
      _coverUrlController.text = college.coverPhotoUrl ?? '';
      _coursesController.text = college.courses.join(', ');
      _naacGradeController.text = college.accreditation.naacGrade ?? '';
      _nirfRankController.text = college.accreditation.nirfRank?.toString() ?? '';
      _ugc = college.accreditation.ugcRecognized;
      _aicte = college.accreditation.aicteApproved;
      _isActive = college.isActive;
      _placementHighController.text = '${college.placements.highestPackageLpa}';
      _placementAvgController.text = '${college.placements.averagePackageLpa}';
      _placementPctController.text = '${college.placements.placementPercentage}';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _universityController.dispose();
    _tuitionMinController.dispose();
    _tuitionMaxController.dispose();
    _hostelFeeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapsUrlController.dispose();
    _logoUrlController.dispose();
    _coverUrlController.dispose();
    _coursesController.dispose();
    _naacGradeController.dispose();
    _nirfRankController.dispose();
    _placementHighController.dispose();
    _placementAvgController.dispose();
    _placementPctController.dispose();
    super.dispose();
  }

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;
  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0;

  CollegeModel _buildModel(String id) {
    final courses = _coursesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return CollegeModel(
      id: id,
      name: _nameController.text.trim(),
      nameLower: _nameController.text.trim().toLowerCase(),
      slug: CollegeSearchUtils.buildSlug(
        _nameController.text.trim(),
        _cityController.text.trim(),
      ),
      city: _cityController.text.trim(),
      state: _state,
      address: _addressController.text.trim(),
      type: _type,
      courses: courses,
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      logoUrl: _logoUrlController.text.trim().isEmpty
          ? null
          : _logoUrlController.text.trim(),
      coverPhotoUrl: _coverUrlController.text.trim().isEmpty
          ? null
          : _coverUrlController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()),
      longitude: double.tryParse(_lngController.text.trim()),
      googleMapsUrl: _mapsUrlController.text.trim().isEmpty
          ? null
          : _mapsUrlController.text.trim(),
      universityName: _universityController.text.trim().isEmpty
          ? null
          : _universityController.text.trim(),
      fees: CollegeFees(
        tuitionMin: _parseInt(_tuitionMinController.text),
        tuitionMax: _parseInt(_tuitionMaxController.text),
        hostelAnnual: _parseInt(_hostelFeeController.text),
      ),
      placements: CollegePlacements(
        highestPackageLpa: _parseDouble(_placementHighController.text),
        averagePackageLpa: _parseDouble(_placementAvgController.text),
        placementPercentage: _parseInt(_placementPctController.text),
      ),
      hostel: CollegeHostel(
        available: _parseInt(_hostelFeeController.text) > 0,
        annualFee: _parseInt(_hostelFeeController.text),
      ),
      accreditation: CollegeAccreditation(
        naacGrade: _naacGradeController.text.trim().isEmpty
            ? null
            : _naacGradeController.text.trim(),
        nirfRank: int.tryParse(_nirfRankController.text.trim()),
        ugcRecognized: _ugc,
        aicteApproved: _aicte,
      ),
      aggregatedRatings: _existing?.aggregatedRatings ??
          const CollegeRatings(
            overall: 0,
            faculty: 0,
            infrastructure: 0,
            placements: 0,
            campusLife: 0,
          ),
      reviewCount: _existing?.reviewCount ?? 0,
      photoUrls: _existing?.photoUrls ?? const [],
      isActive: _isActive,
      createdAt: _existing?.createdAt,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(collegeRepositoryProvider);
      final uid = ref.read(authProvider).user?.uid;
      final id = widget.collegeId ?? const Uuid().v4();
      final model = _buildModel(id);

      if (widget.collegeId == null) {
        await repo.createCollege(model);
      } else {
        await repo.updateCollege(model, updatedBy: uid);
      }

      ref.invalidate(collegeByIdProvider(id));
      ref.invalidate(featuredCollegesProvider);
      ref.invalidate(adminCollegeSearchProvider);

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: widget.collegeId == null
              ? 'College created'
              : 'College updated',
        );
        context.go(RouteNames.adminColleges);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: '$e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.collegeId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit College' : 'Add College'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.adminColleges),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic Info',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: _decoration('College Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _decoration('City'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _state,
                      decoration: _decoration('State'),
                      items: CollegeConstants.indianStates
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _state = v ?? _state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _decoration('Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: _decoration('Type'),
                items: CollegeConstants.collegeTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 24),
              Text('Media & Links', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(controller: _logoUrlController, decoration: _decoration('Logo URL')),
              const SizedBox(height: 12),
              TextFormField(controller: _coverUrlController, decoration: _decoration('Cover Photo URL')),
              const SizedBox(height: 12),
              TextFormField(controller: _websiteController, decoration: _decoration('Website')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latController, decoration: _decoration('Latitude'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _lngController, decoration: _decoration('Longitude'))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _mapsUrlController, decoration: _decoration('Google Maps URL')),
              const SizedBox(height: 24),
              Text('University & Accreditation', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(controller: _universityController, decoration: _decoration('University')),
              const SizedBox(height: 12),
              TextFormField(controller: _naacGradeController, decoration: _decoration('NAAC Grade')),
              const SizedBox(height: 12),
              TextFormField(controller: _nirfRankController, decoration: _decoration('NIRF Rank'), keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('UGC Recognized'),
                value: _ugc,
                onChanged: (v) => setState(() => _ugc = v),
              ),
              SwitchListTile(
                title: const Text('AICTE Approved'),
                value: _aicte,
                onChanged: (v) => setState(() => _aicte = v),
              ),
              const SizedBox(height: 24),
              Text('Fees, Placements, Courses', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _tuitionMinController, decoration: _decoration('Tuition Min'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _tuitionMaxController, decoration: _decoration('Tuition Max'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _hostelFeeController, decoration: _decoration('Hostel Annual Fee'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _placementHighController, decoration: _decoration('Highest LPA'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _placementAvgController, decoration: _decoration('Average LPA'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _placementPctController, decoration: _decoration('Placement %'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coursesController,
                decoration: _decoration('Courses (comma separated)'),
                maxLines: 2,
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isEdit ? 'Save Changes' : 'Create College',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.gray100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}