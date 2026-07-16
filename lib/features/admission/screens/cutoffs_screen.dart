import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/admission_constants.dart';
import '../providers/admission_provider.dart';

class CutoffsScreen extends ConsumerStatefulWidget {
  const CutoffsScreen({super.key});

  @override
  ConsumerState<CutoffsScreen> createState() => _CutoffsScreenState();
}

class _CutoffsScreenState extends ConsumerState<CutoffsScreen> {
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();

  @override
  void dispose() {
    _collegeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cutoffsAsync = ref.watch(filteredCutoffsProvider);
    final filters = ref.watch(cutoffFilterProvider);
    final examsAsync = ref.watch(entranceExamsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Cutoffs'),
      ),
      body: cutoffsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cutoffs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _collegeController,
                decoration: InputDecoration(
                  hintText: 'Search college...',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => ref.read(cutoffFilterProvider.notifier).update(
                      filters.copyWith(collegeQuery: v),
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _courseController,
                decoration: InputDecoration(
                  hintText: 'Search course / branch...',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => ref.read(cutoffFilterProvider.notifier).update(
                      filters.copyWith(courseQuery: v),
                    ),
              ),
              const SizedBox(height: 12),
              examsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (exams) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Exams'),
                        selected: filters.examId == null,
                        onSelected: (_) => ref.read(cutoffFilterProvider.notifier).update(
                              filters.copyWith(examId: null),
                            ),
                      ),
                      ...exams.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(e.slug.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11)),
                            selected: filters.examId == e.id,
                            onSelected: (_) => ref.read(cutoffFilterProvider.notifier).update(
                                  filters.copyWith(examId: e.id),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AdmissionConstants.reservationCategories.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c, style: GoogleFonts.poppins(fontSize: 11)),
                        selected: filters.category == c,
                        onSelected: (_) => ref.read(cutoffFilterProvider.notifier).update(
                              filters.copyWith(category: filters.category == c ? null : c),
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (cutoffs.isEmpty)
                const Center(child: Text('No cutoff records match your filters'))
              else
                ...cutoffs.map(
                  (c) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(c.collegeName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        '${c.course}${c.branch.isNotEmpty ? ' · ${c.branch}' : ''}\n'
                        '${c.examName} · ${c.year} · ${c.round} · ${c.category}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        c.cutoffRank != null
                            ? 'Rank ${c.cutoffRank}'
                            : c.cutoffPercentile != null
                                ? '${c.cutoffPercentile!.toStringAsFixed(1)}%'
                                : c.cutoffMarks != null
                                    ? '${c.cutoffMarks!.toStringAsFixed(0)} marks'
                                    : '-',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
