import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/cache/compare_session_cache.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/compare_constants.dart';
import '../models/college_comparison_result.dart';
import '../providers/compare_basket_provider.dart';
import '../widgets/ai_compare_insights_panel.dart';
import '../widgets/compare_table_widget.dart';

class CollegeCompareScreen extends ConsumerStatefulWidget {
  final List<String> collegeIds;

  const CollegeCompareScreen({required this.collegeIds, super.key});

  @override
  ConsumerState<CollegeCompareScreen> createState() =>
      _CollegeCompareScreenState();
}

class _CollegeCompareScreenState extends ConsumerState<CollegeCompareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.collegeIds.isNotEmpty) {
        ref.read(compareBasketProvider.notifier).setColleges(widget.collegeIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.collegeIds.take(CompareConstants.maxColleges).toList();
    final cached = CompareSessionCache.get(ids);
    final comparisonAsync = ref.watch(compareCollegesProvider(ids));
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare Colleges',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Up to ${CompareConstants.maxColleges} colleges • Verified data only',
              style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.gray500),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear selection',
            onPressed: () {
              ref.read(compareBasketProvider.notifier).clear();
              context.go(RouteNames.collegeSearch);
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: comparisonAsync.when(
        loading: () {
          if (cached != null) {
            return _buildCompareContent(cached, isWide);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, _) {
          if (cached != null) {
            return _buildCompareContent(cached, isWide);
          }
          return Center(child: Text('Failed to load: $e'));
        },
        data: (result) {
          if (result == null || result.colleges.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.compare_arrows_rounded,
                        size: 64, color: AppTheme.gray400),
                    const SizedBox(height: 16),
                    Text(
                      'Select at least ${CompareConstants.minCollegesToCompare} colleges',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(RouteNames.collegeSearch),
                      child: const Text('Search Colleges'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildCompareContent(result, isWide);
        },
      ),
    );
  }

  Widget _buildCompareContent(CollegeComparisonResult result, bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              result.summary,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          CompareTableWidget(result: result),
          const SizedBox(height: 28),
          AiCompareInsightsPanel(insights: result.insights),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Best values highlighted in green. All data from Firestore.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
