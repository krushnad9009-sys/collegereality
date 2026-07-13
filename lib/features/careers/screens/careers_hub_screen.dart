import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

class CareersHubScreen extends StatelessWidget {
  const CareersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: const Text('Careers Hub'),
      ),
      body: ListView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        children: [
          Text('Build your career',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Internships, jobs, company insights, and verified alumni network.',
            style: GoogleFonts.poppins(color: AppTheme.gray600, height: 1.5),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: isWide ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.4 : 1.1,
            children: [
              _tile(Icons.work_outline, 'Internships', 'Find & apply', AppTheme.primaryColor,
                  () => context.push(RouteNames.careersInternships)),
              _tile(Icons.business_center_outlined, 'Jobs', 'Fresher & experienced',
                  AppTheme.secondaryColor, () => context.push(RouteNames.careersJobs)),
              _tile(Icons.apartment_outlined, 'Companies', 'Profiles & reviews',
                  AppTheme.accentColor, () => context.push(RouteNames.careersCompanies)),
              _tile(Icons.people_outline, 'Alumni', 'Network & guidance', const Color(0xFF7C3AED),
                  () => context.push(RouteNames.careersAlumni)),
              _tile(Icons.bookmark_outline, 'Saved', 'Internships & jobs',
                  AppTheme.warningColor, () => context.push(RouteNames.careersSaved)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
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
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            ],
          ),
        ),
      ),
    );
  }
}
