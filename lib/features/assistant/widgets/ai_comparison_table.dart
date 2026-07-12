import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/ai_comparison_result.dart';

class AiComparisonTable extends StatelessWidget {
  final AiComparisonResult comparison;

  const AiComparisonTable({required this.comparison, super.key});

  @override
  Widget build(BuildContext context) {
    if (comparison.colleges.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 40,
        columnSpacing: 16,
        headingTextStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        columns: [
          const DataColumn(label: Text('Metric')),
          ...comparison.colleges.map(
            (c) => DataColumn(
              label: SizedBox(
                width: 100,
                child: Text(
                  c.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
        rows: comparison.rows.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(row.metric)),
              ...row.values.asMap().entries.map((entry) {
                final isWinner = row.winnerIndex == entry.key;
                return DataCell(
                  Text(
                    entry.value,
                    style: GoogleFonts.poppins(
                      fontWeight:
                          isWinner ? FontWeight.w700 : FontWeight.w400,
                      color: isWinner ? AppTheme.accentColor : null,
                    ),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}
