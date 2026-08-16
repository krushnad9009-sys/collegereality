import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/ai_comparison_result.dart';

class AiComparisonTable extends StatelessWidget {
  final AiComparisonResult comparison;

  const AiComparisonTable({required this.comparison, super.key});

  @override
  Widget build(BuildContext context) {
    if (comparison.colleges.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 40,
          columnSpacing: 16,
          border: TableBorder(
            horizontalInside: BorderSide(color: tokens.borderSubtle),
          ),
          headingRowColor: WidgetStatePropertyAll(tokens.surfaceMuted),
          headingTextStyle: AppFonts.plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
          dataTextStyle: AppFonts.plusJakarta(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.textSecondary,
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
          rows: comparison.rows.asMap().entries.map((rowEntry) {
            final rowIndex = rowEntry.key;
            final row = rowEntry.value;
            return DataRow(
              color: WidgetStatePropertyAll(
                rowIndex.isOdd
                    ? tokens.surfaceMuted.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
              cells: [
                DataCell(
                  Text(
                    row.metric,
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                ...row.values.asMap().entries.map((entry) {
                  final isWinner = row.winnerIndex == entry.key;
                  return DataCell(
                    Text(
                      entry.value,
                      style: AppFonts.plusJakarta(
                        fontSize: 13,
                        fontWeight:
                            isWinner ? FontWeight.w700 : FontWeight.w500,
                        color: isWinner
                            ? AppTheme.accentColor
                            : tokens.textSecondary,
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
