import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';
import '../models/entrance_exam_model.dart';
import '../providers/admission_provider.dart';

class EntranceExamsScreen extends ConsumerWidget {
  const EntranceExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(filteredExamsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Entrance Exams'),
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (exams) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search exams (JEE, NEET, CET...)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (q) => ref.read(examSearchProvider.notifier).setQuery(q),
              ),
              const SizedBox(height: 16),
              if (exams.isEmpty)
                const Center(child: Text('No exams found'))
              else
                ...exams.map((exam) => _ExamCard(exam: exam)),
            ],
          );
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final EntranceExamModel exam;

  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(exam.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        subtitle: Text(exam.category, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exam.conductingBody.isNotEmpty)
                  _section('Conducting Body', exam.conductingBody),
                if (exam.eligibility.isNotEmpty) _section('Eligibility', exam.eligibility),
                if (exam.examPattern.isNotEmpty) _section('Exam Pattern', exam.examPattern),
                if (exam.syllabus.isNotEmpty) _section('Syllabus', exam.syllabus),
                if (exam.importantDates.isNotEmpty) ...[
                  Text('Important Dates',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  ...exam.importantDates.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${d.label}: ${DateFormat('MMM d, yyyy').format(d.date)}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
                      ),
                    ),
                  ),
                ],
                if (exam.officialWebsite.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(exam.officialWebsite)),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Official Website'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(body, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600, height: 1.4)),
        ],
      ),
    );
  }
}
