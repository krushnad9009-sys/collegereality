import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/admission_constants.dart';
import '../../../core/widgets/index.dart';
import '../models/admission_prediction_model.dart';
import '../models/scholarship_model.dart';
import '../providers/admission_provider.dart';

class SavedPredictionsScreen extends ConsumerWidget {
  const SavedPredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(userPredictionsProvider);
    final savedIds = ref.watch(savedScholarshipIdsProvider).valueOrNull ?? {};
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Saved'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Predictions'),
              Tab(text: 'Scholarships'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            predictionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (predictions) {
                if (predictions.isEmpty) {
                  return const Center(child: Text('No saved predictions yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    final p = predictions[index];
                    return _PredictionTile(
                      prediction: p,
                      onDelete: () => ref
                          .read(admissionRepositoryProvider)
                          .deletePrediction(p.id),
                    );
                  },
                );
              },
            ),
            scholarshipsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final saved = all.where((s) => savedIds.contains(s.id)).toList();
                if (saved.isEmpty) {
                  return const Center(child: Text('No saved scholarships yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: saved.length,
                  itemBuilder: (context, index) {
                    return _SavedScholarshipTile(scholarship: saved[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionTile extends StatelessWidget {
  final AdmissionPredictionModel prediction;
  final VoidCallback onDelete;

  const _PredictionTile({required this.prediction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final high = prediction.results
        .where((r) => r.chance == AdmissionConstants.chanceHigh)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(prediction.examName,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${prediction.category} · ${DateFormat('MMM d, yyyy').format(prediction.createdAt)}\n'
          '$high high-chance colleges out of ${prediction.results.length}',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            try {
              onDelete();
              if (context.mounted) {
                SnackBarHelper.showSuccessSnackBar(context, message: 'Deleted');
              }
            } catch (e) {
              if (context.mounted) {
                SnackBarHelper.showErrorSnackBar(context, message: e.toString());
              }
            }
          },
        ),
      ),
    );
  }
}

class _SavedScholarshipTile extends StatelessWidget {
  final ScholarshipModel scholarship;

  const _SavedScholarshipTile({required this.scholarship});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(scholarship.name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${scholarship.providerLabel} · ${scholarship.amount}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
      ),
    );
  }
}
