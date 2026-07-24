import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../colleges/models/college_model.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../ranking/widgets/cr_score_badge_widget.dart';
import '../models/college_comparison_result.dart';

class CompareTableWidget extends StatelessWidget {
  final CollegeComparisonResult result;

  const CompareTableWidget({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final colleges = result.colleges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CollegeHeaders(colleges: colleges),
        const SizedBox(height: 12),
        if (isWide)
          _DesktopTable(result: result)
        else
          _MobileCards(result: result),
      ],
    );
  }
}

class _CollegeHeaders extends StatelessWidget {
  final List<CollegeModel> colleges;

  const _CollegeHeaders({required this.colleges});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colleges.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                c.locationLabel,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.gray500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  CrScoreBadgeWidget(
                    score: CrScoreEngine.effectiveScore(c),
                    fontSize: 10,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified_outlined,
                      size: 12, color: AppTheme.accentColor),
                  const SizedBox(width: 4),
                  Text(
                    '${c.reviewCount} verified reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final CollegeComparisonResult result;

  const _DesktopTable({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 44,
        columnSpacing: 20,
        headingTextStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        columns: [
          const DataColumn(label: Text('Metric')),
          ...result.colleges.map(
            (c) => DataColumn(
              label: SizedBox(
                width: 120,
                child: Text(
                  c.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
        rows: result.rows.map((row) => _dataRow(row)).toList(),
      ),
    );
  }

  DataRow _dataRow(ComparisonRow row) {
    return DataRow(
      cells: [
        DataCell(Text(row.metric)),
        ...row.values.asMap().entries.map((entry) {
          final isWinner = row.winnerIndex == entry.key;
          return DataCell(
            _ValueCell(value: entry.value, isWinner: isWinner),
          );
        }),
      ],
    );
  }
}

class _MobileCards extends StatelessWidget {
  final CollegeComparisonResult result;

  const _MobileCards({required this.result});

  @override
  Widget build(BuildContext context) {
    String? lastCategory;
    return Column(
      children: result.rows.expand((row) {
        final widgets = <Widget>[];
        if (row.category != lastCategory) {
          lastCategory = row.category;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  row.category,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          );
        }
        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppTheme.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.metric,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...row.values.asMap().entries.map((entry) {
                    final college = result.colleges[entry.key];
                    final isWinner = row.winnerIndex == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              college.name,
                              style: GoogleFonts.poppins(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: _ValueCell(
                              value: entry.value,
                              isWinner: isWinner,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
        return widgets;
      }).toList(),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final String value;
  final bool isWinner;

  const _ValueCell({required this.value, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
        color: isWinner ? AppTheme.accentColor : null,
      ),
    );
  }
}
