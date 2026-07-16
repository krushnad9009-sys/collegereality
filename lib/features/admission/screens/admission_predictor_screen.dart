import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/admission_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admission_prediction_model.dart';
import '../models/entrance_exam_model.dart';
import '../providers/admission_provider.dart';
import '../utils/admission_utils.dart';

class AdmissionPredictorScreen extends ConsumerStatefulWidget {
  const AdmissionPredictorScreen({super.key});

  @override
  ConsumerState<AdmissionPredictorScreen> createState() =>
      _AdmissionPredictorScreenState();
}

class _AdmissionPredictorScreenState extends ConsumerState<AdmissionPredictorScreen> {
  EntranceExamModel? _selectedExam;
  final _rankController = TextEditingController();
  final _percentileController = TextEditingController();
  final _marksController = TextEditingController();
  String _category = 'General';
  String _gender = 'All';
  final _stateController = TextEditingController();
  final _universityController = TextEditingController();
  List<PredictionResultModel> _results = [];
  bool _isPredicting = false;

  @override
  void dispose() {
    _rankController.dispose();
    _percentileController.dispose();
    _marksController.dispose();
    _stateController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    if (_selectedExam == null) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Select an exam first');
      return;
    }

    setState(() => _isPredicting = true);
    try {
      final cutoffs = await ref.read(admissionRepositoryProvider).getCutoffs(
            examId: _selectedExam!.id,
          );
      final results = predictAdmission(
        cutoffs: cutoffs,
        scoreType: _selectedExam!.scoreType,
        rank: int.tryParse(_rankController.text.trim()),
        percentile: double.tryParse(_percentileController.text.trim()),
        marks: double.tryParse(_marksController.text.trim()),
        category: _category,
        gender: _gender,
        state: _stateController.text.trim(),
        homeUniversity: _universityController.text.trim(),
      );
      setState(() => _results = results);
      if (results.isEmpty && mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'No matching cutoff data found for your inputs.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPredicting = false);
    }
  }

  Future<void> _savePrediction() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || _selectedExam == null || _results.isEmpty) return;

    try {
      await ref.read(admissionRepositoryProvider).savePrediction(
            AdmissionPredictionModel(
              id: '',
              userId: user.uid,
              examId: _selectedExam!.id,
              examName: _selectedExam!.name,
              rank: int.tryParse(_rankController.text.trim()),
              percentile: double.tryParse(_percentileController.text.trim()),
              marks: double.tryParse(_marksController.text.trim()),
              scoreType: _selectedExam!.scoreType,
              category: _category,
              gender: _gender,
              state: _stateController.text.trim(),
              homeUniversity: _universityController.text.trim(),
              results: _results,
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Prediction saved');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(entranceExamsProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Admission Predictor'),
      ),
      body: ListView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        children: [
          Text(
            'AI Admission Predictor',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Predictions are based on previous year cutoff data in Firestore — not estimated.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
          ),
          const SizedBox(height: 16),
          examsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (exams) => DropdownButtonFormField<EntranceExamModel>(
              initialValue: _selectedExam,
              decoration: InputDecoration(
                labelText: 'Exam',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: exams
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedExam = v;
                _results = [];
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedExam?.scoreType == AdmissionConstants.scoreTypeRank)
            TextField(
              controller: _rankController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Rank',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          if (_selectedExam?.scoreType == AdmissionConstants.scoreTypePercentile)
            TextField(
              controller: _percentileController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Percentile',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          if (_selectedExam?.scoreType == AdmissionConstants.scoreTypeMarks)
            TextField(
              controller: _marksController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Marks',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: AdmissionConstants.reservationCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'General'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: AdmissionConstants.genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v ?? 'All'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stateController,
            decoration: InputDecoration(
              labelText: 'State (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _universityController,
            decoration: InputDecoration(
              labelText: 'Home University (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isPredicting ? null : _runPrediction,
            child: _isPredicting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Predict Colleges', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _savePrediction,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save Prediction'),
            ),
            const SizedBox(height: 24),
            Text('Results', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ..._results.map((r) => _ResultCard(result: r)),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PredictionResultModel result;

  const _ResultCard({required this.result});

  Color _chanceColor(String chance) {
    switch (chance) {
      case AdmissionConstants.chanceHigh:
        return AppTheme.accentColor;
      case AdmissionConstants.chanceMedium:
        return AppTheme.warningColor;
      default:
        return AppTheme.errorColor;
    }
  }

  String _chanceLabel(String chance) {
    switch (chance) {
      case AdmissionConstants.chanceHigh:
        return 'High Chance';
      case AdmissionConstants.chanceMedium:
        return 'Medium Chance';
      default:
        return 'Low Chance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(result.collegeName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _chanceColor(result.chance).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _chanceLabel(result.chance),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _chanceColor(result.chance),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${result.course}${result.branch.isNotEmpty ? ' · ${result.branch}' : ''}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
            ),
            const SizedBox(height: 8),
            Text(result.explanation,
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
