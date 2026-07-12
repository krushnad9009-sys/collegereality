import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/verified_placement_stats.dart';

class BranchPlacementChart extends StatelessWidget {
  final List<BranchPlacementStat> branches;

  const BranchPlacementChart({required this.branches, super.key});

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return Text(
        'Branch-wise statistics appear after verified placement approvals.',
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
      );
    }

    final maxAvg = branches
        .map((e) => e.avgPackageLpa)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: branches.take(8).map((branch) {
        final widthFactor =
            maxAvg > 0 ? (branch.avgPackageLpa / maxAvg).clamp(0.05, 1.0) : 0.05;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      branch.branch,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${branch.avgPackageLpa.toStringAsFixed(1)} LPA',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widthFactor,
                  minHeight: 8,
                  backgroundColor: AppTheme.gray200,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${branch.count} verified • ${branch.placementRate.toStringAsFixed(0)}% full-time',
                style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.gray500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
