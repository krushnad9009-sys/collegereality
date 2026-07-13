import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';
import '../utils/resume_scoring_utils.dart';

class ResumeHubScreen extends ConsumerWidget {
  const ResumeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeAsync = ref.watch(studentResumeProvider);
    final userAsync = ref.watch(currentUserDetailProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Resume'),
      ),
      body: resumeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (resume) {
          final user = userAsync.valueOrNull;
          final scoreResult = scoreResume(
            user: user,
            hasResumeFile: resume != null,
            fileSizeBytes: resume?.fileSizeBytes ?? 0,
            extractedSkills: resume?.extractedSkills ?? [],
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ScoreCard(score: resume?.score ?? scoreResult.score),
              const SizedBox(height: 16),
              if (resume != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(resume.fileName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Updated ${resume.updatedAt.toLocal().toString().split(' ').first}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () => launchUrl(Uri.parse(resume.downloadUrl)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(resume.downloadUrl)),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview / Download'),
                ),
              ] else
                Text(
                  'No resume uploaded yet. Upload PDF or DOCX to apply with resume.',
                  style: GoogleFonts.poppins(color: AppTheme.gray600),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _uploadResume(context, ref),
                icon: const Icon(Icons.upload_file),
                label: Text(resume == null ? 'Upload Resume' : 'Replace Resume'),
              ),
              const SizedBox(height: 24),
              Text('AI Improvement Tips',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              ...(resume?.suggestions.isNotEmpty == true
                      ? resume!.suggestions
                      : scoreResult.suggestions)
                  .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: GoogleFonts.poppins(fontSize: 13))),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _uploadResume(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      final ext = file.extension ?? 'pdf';
      final url = await ref.read(resumeStorageServiceProvider).uploadResume(
            userId: user.uid,
            bytes: file.bytes!,
            extension: ext,
          );
      final userDetail = await ref.read(currentUserDetailProvider.future);
      final extracted = extractSkillsFromFileName(file.name);
      final scoreResult = scoreResume(
        user: userDetail,
        hasResumeFile: true,
        fileSizeBytes: file.size,
        extractedSkills: extracted,
      );
      final resume = StudentResumeModel(
        userId: user.uid,
        fileName: file.name,
        downloadUrl: url,
        fileSizeBytes: file.size,
        score: scoreResult.score,
        suggestions: scoreResult.suggestions,
        extractedSkills: extracted,
        updatedAt: DateTime.now(),
      );
      await ref.read(careersRepositoryProvider).saveStudentResume(resume);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Resume uploaded successfully');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppTheme.accentColor
        : score >= 40
            ? AppTheme.warningColor
            : AppTheme.errorColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    color: color,
                  ),
                ),
                Text('$score',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resume Score',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    score >= 70
                        ? 'Strong profile — ready to apply!'
                        : 'Improve your resume using the tips below.',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
