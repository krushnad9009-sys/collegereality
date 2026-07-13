import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

class AdmissionHubScreen extends StatelessWidget {
  const AdmissionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final crossAxisCount = isWide ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: const Text('Admission Hub'),
      ),
      body: ListView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        children: [
          Text(
            'Your admission companion',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scholarships, entrance exams, cutoffs, and AI-powered college predictions — all in one place.',
            style: GoogleFonts.poppins(color: AppTheme.gray600, height: 1.5),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.4 : 1.1,
            children: [
              _HubTile(
                icon: Icons.school_outlined,
                title: 'Scholarships',
                subtitle: 'Govt & private schemes',
                color: AppTheme.primaryColor,
                onTap: () => context.push(RouteNames.admissionScholarships),
              ),
              _HubTile(
                icon: Icons.quiz_outlined,
                title: 'Entrance Exams',
                subtitle: 'JEE, NEET, CET & more',
                color: AppTheme.secondaryColor,
                onTap: () => context.push(RouteNames.admissionExams),
              ),
              _HubTile(
                icon: Icons.analytics_outlined,
                title: 'Cutoffs',
                subtitle: 'Previous year data',
                color: AppTheme.accentColor,
                onTap: () => context.push(RouteNames.admissionCutoffs),
              ),
              _HubTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Predictor',
                subtitle: 'AI college chances',
                color: const Color(0xFF7C3AED),
                onTap: () => context.push(RouteNames.admissionPredictor),
              ),
              _HubTile(
                icon: Icons.bookmark_outline,
                title: 'Saved',
                subtitle: 'Scholarships & predictions',
                color: AppTheme.warningColor,
                onTap: () => context.push(RouteNames.savedPredictions),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
