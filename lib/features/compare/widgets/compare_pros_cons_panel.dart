import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/college_comparison_result.dart';

class CompareProsConsPanel extends StatelessWidget {
  final List<CollegeProsCons> items;

  const CompareProsConsPanel({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    if (items.every((item) => item.pros.isEmpty && item.cons.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pros & Cons from Verified Reviews',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Most frequently mentioned points from verified student feedback.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _CollegeProsConsCard(item: item)),
      ],
    );
  }
}

class _CollegeProsConsCard extends StatelessWidget {
  final CollegeProsCons item;

  const _CollegeProsConsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.collegeName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (item.pros.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pros',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
              ),
              ...item.pros.map(
                (pro) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.add_circle_outline,
                          size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(pro, style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (item.cons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Cons',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningColor,
                ),
              ),
              ...item.cons.map(
                (con) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.remove_circle_outline,
                          size: 14, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(con, style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
