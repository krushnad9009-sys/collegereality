import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/ranking_provider.dart';

class CompareRecommendationsScreen extends ConsumerWidget {
  const CompareRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(compareRecommendationsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top 5 Compare Picks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final items = itemsAsync.valueOrNull ?? [];
              if (items.length >= 2) {
                context.push(RouteNames.comparePath(
                  ids: items.take(3).map((i) => i.college.id).toList(),
                ));
              }
            },
            child: const Text('Compare'),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = items[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text('#${item.rank}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.college.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${item.overallScore.toStringAsFixed(0)}/100',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.whyRecommended,
                        style: GoogleFonts.poppins(color: AppTheme.gray700, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetricChip(label: 'Fees', value: item.feesLabel),
                        const SizedBox(width: 8),
                        _MetricChip(label: 'ROI', value: '${item.roiScore.toStringAsFixed(0)}/100'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Expected: ${item.expectedPlacement}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600)),
                    if (item.strengths.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Strengths',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      ...item.strengths.map((s) => Text('• $s', style: const TextStyle(fontSize: 12))),
                    ],
                    if (item.weaknesses.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Weaknesses',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      ...item.weaknesses.map((w) => Text('• $w', style: const TextStyle(fontSize: 12))),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          context.push(RouteNames.collegeDetailsPath(item.college.id)),
                      child: const Text('View college'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}
