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
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final colleges = result.colleges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CollegeHeaderCards(colleges: colleges),
        const SizedBox(height: 16),
        if (isWide)
          _DesktopTable(result: result)
        else
          _MobileCards(result: result),
      ],
    );
  }
}

class _CollegeHeaderCards extends StatelessWidget {
  final List<CollegeModel> colleges;

  const _CollegeHeaderCards({required this.colleges});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 24) / colleges.length
            : 240.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colleges.asMap().entries.map((entry) {
              final college = entry.value;
              return Container(
                width: cardWidth.clamp(220, 320),
                margin: EdgeInsets.only(
                  right: entry.key == colleges.length - 1 ? 0 : 12,
                ),
                child: _AnimatedCompareCard(
                  delayMs: entry.key * 80,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.gray200),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDark.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          college.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          college.locationLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.gray500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CrScoreBadgeWidget(
                          score: CrScoreEngine.effectiveScore(college),
                          showGrade: true,
                          fontSize: 11,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${college.reviewCount} verified reviews',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _AnimatedCompareCard extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedCompareCard({
    required this.child,
    required this.delayMs,
  });

  @override
  State<_AnimatedCompareCard> createState() => _AnimatedCompareCardState();
}

class _AnimatedCompareCardState extends State<_AnimatedCompareCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: widget.child,
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final CollegeComparisonResult result;

  const _DesktopTable({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.gray200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 48,
          columnSpacing: 24,
          headingTextStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          columns: [
            const DataColumn(label: Text('Metric')),
            ...result.colleges.map(
              (c) => DataColumn(
                label: SizedBox(
                  width: 140,
                  child: Text(
                    c.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
          rows: result.rows.map(_dataRow).toList(),
        ),
      ),
    );
  }

  DataRow _dataRow(ComparisonRow row) {
    return DataRow(
      cells: [
        DataCell(Text(row.metric)),
        ...row.values.asMap().entries.map((entry) {
          return DataCell(
            _ValueCell(value: entry.value, isWinner: row.winnerIndex == entry.key),
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
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 10),
                  ...row.values.asMap().entries.map((entry) {
                    final college = result.colleges[entry.key];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              college.name,
                              style: GoogleFonts.poppins(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _ValueCell(
                            value: entry.value,
                            isWinner: row.winnerIndex == entry.key,
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
    return Container(
      padding: isWinner
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : EdgeInsets.zero,
      decoration: isWinner
          ? BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
          color: isWinner ? AppTheme.accentColor : null,
        ),
      ),
    );
  }
}
