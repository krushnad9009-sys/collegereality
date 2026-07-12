import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../providers/placement_provider.dart';

class PlacementInsightsPanel extends ConsumerWidget {
  final String collegeId;

  const PlacementInsightsPanel({required this.collegeId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync =
        ref.watch(collegePlacementInsightsProvider(collegeId));

    return insightsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Text('Failed to load insights: $e'),
      data: (insights) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.08),
                AppTheme.secondaryColor.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'AI Placement Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Summarized from admin-approved verified records only',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.gray500,
                ),
              ),
              const SizedBox(height: 12),
              ...insights.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          line,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
