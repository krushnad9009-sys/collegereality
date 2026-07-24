import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';

class HowCrScoreWorksScreen extends StatelessWidget {
  const HowCrScoreWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How CR Score Works'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'College Reality Score',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'India\'s most trusted college rating built entirely from verified student feedback.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.gray600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Verified feedback only',
            body:
                'Only reviews from verified students and verified alumni of a college are included. '
                'Rejected, fake, spam, deleted, and reported reviews never affect CR Score.',
            icon: Icons.verified_user_outlined,
          ),
          _Section(
            title: 'Weighted categories',
            body:
                'Education Quality (25%), Placements (25%), Campus Life (20%), Infrastructure (15%), '
                'Safety & Discipline (15%). Each category is calculated from verified review ratings.',
            icon: Icons.pie_chart_outline,
          ),
          _Section(
            title: 'Confidence levels',
            body:
                '0–9 reviews: Not enough data\n'
                '10–49: Low Confidence\n'
                '50–199: Medium Confidence\n'
                '200–999: High Confidence\n'
                '1000+: Very High Confidence',
            icon: Icons.insights_outlined,
          ),
          _Section(
            title: 'Grades',
            body:
                '95–100 A+ · 90–94 A · 85–89 A- · 80–84 B+ · 75–79 B · 70–74 B- · '
                '65–69 C+ · 60–64 C · 50–59 D · Below 50 F',
            icon: Icons.grade_outlined,
          ),
          _Section(
            title: 'Security & fairness',
            body:
                'Each verified user can submit one review per college. Scores recalculate automatically '
                'when reviews are added, edited, rejected, or removed. Admins can trigger a full recalculation.',
            icon: Icons.security_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color guide',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _ColorRow(
                    color: CrScoreConstants.colorForScore(85),
                    label: '80+ Excellent',
                  ),
                  _ColorRow(
                    color: CrScoreConstants.colorForScore(70),
                    label: '60–79 Good',
                  ),
                  _ColorRow(
                    color: CrScoreConstants.colorForScore(45),
                    label: 'Below 60 Needs improvement',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _Section({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.gray600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }
}
