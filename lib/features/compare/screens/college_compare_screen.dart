import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/cache/compare_session_cache.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/compare_constants.dart';
import '../models/college_comparison_result.dart';
import '../providers/compare_basket_provider.dart';
import '../widgets/compare_saved_sheet.dart';
import '../widgets/compare_add_college_sheet.dart';
import '../widgets/compare_ai_summary_panel.dart';
import '../widgets/compare_pros_cons_panel.dart';
import '../widgets/compare_table_widget.dart';
import '../widgets/compare_winner_banner.dart';
import '../widgets/ai_compare_insights_panel.dart';

class CollegeCompareScreen extends ConsumerStatefulWidget {
  final List<String> collegeIds;

  const CollegeCompareScreen({required this.collegeIds, super.key});

  @override
  ConsumerState<CollegeCompareScreen> createState() =>
      _CollegeCompareScreenState();
}

class _CollegeCompareScreenState extends ConsumerState<CollegeCompareScreen> {
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.collegeIds.isNotEmpty) {
        ref.read(compareBasketProvider.notifier).setColleges(widget.collegeIds);
      }
    });
  }

  Future<void> _saveComparison(CollegeComparisonResult result) async {
    final service = await ref.read(compareSavedServiceProvider.future);
    await service.save(
      collegeIds: result.colleges.map((c) => c.id).toList(),
      title: result.colleges.map((c) => c.name).join(' vs '),
    );
    ref.invalidate(savedComparisonsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comparison saved for later')),
      );
    }
  }

  Future<void> _shareComparison(CollegeComparisonResult result) async {
    final link = RouteNames.comparePath(
      ids: result.colleges.map((c) => c.id).toList(),
    );
    await ref.read(compareShareServiceProvider).shareLink(link);
  }

  Future<void> _shareImage() async {
    await ref.read(compareShareServiceProvider).shareImage(_shareKey);
  }

  Future<void> _sharePdf(CollegeComparisonResult result) async {
    await ref.read(compareShareServiceProvider).sharePdf(result);
  }

  void _removeCollege(String collegeId) {
    ref.read(compareBasketProvider.notifier).remove(collegeId);
    final ids = ref.read(compareBasketProvider).collegeIds;
    CompareSessionCache.clear();
    if (ids.length >= CompareConstants.minCollegesToCompare) {
      context.go(RouteNames.comparePath(ids: ids));
    } else {
      context.go(RouteNames.collegeSearch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final basket = ref.watch(compareBasketProvider);
    final ids = basket.collegeIds.take(CompareConstants.maxColleges).toList();
    final cached = CompareSessionCache.get(ids);
    final comparisonAsync = ref.watch(compareCollegesProvider(ids));
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Compare Colleges',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: tokens.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${CompareConstants.minCollegesToCompare}-${CompareConstants.maxColleges} colleges · Verified data only',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        actions: [
          IconButton(
            tooltip: 'Saved comparisons',
            onPressed: () => showSavedComparisonsSheet(context, ref),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          IconButton(
            tooltip: 'Add college',
            onPressed: basket.isFull ? null : () => showCompareAddCollegeSheet(context, ref),
            icon: const Icon(Icons.add),
          ),
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
                      'Select ${CompareConstants.minCollegesToCompare} to ${CompareConstants.maxColleges} colleges',
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
    final winner = result.overallWinnerIndex != null
        ? result.colleges[result.overallWinnerIndex!]
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isWide ? AppSpacing.section : AppSpacing.lg,
        isWide ? AppSpacing.section : AppSpacing.lg,
        isWide ? AppSpacing.section : AppSpacing.lg,
        AppSpacing.section,
      ),
      child: RepaintBoundary(
        key: _shareKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _saveComparison(result),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Save'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _shareComparison(result),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Share Link'),
                ),
                OutlinedButton.icon(
                  onPressed: _shareImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Share Image'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sharePdf(result),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Share PDF'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (winner != null) ...[
              CompareWinnerBanner(college: winner),
              const SizedBox(height: AppSpacing.xl),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                result.summary,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: result.colleges.map((college) {
                return InputChip(
                  label: Text(college.name, style: GoogleFonts.poppins(fontSize: 11)),
                  onDeleted: result.colleges.length >
                          CompareConstants.minCollegesToCompare
                      ? () => _removeCollege(college.id)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            CompareTableWidget(result: result),
            const SizedBox(height: AppSpacing.section),
            CompareAiSummaryPanel(summary: result.aiSummary),
            const SizedBox(height: 24),
            CompareProsConsPanel(items: result.prosCons),
            const SizedBox(height: 24),
            AiCompareInsightsPanel(insights: result.insights),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Best values highlighted in green. All data from verified student feedback.',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
