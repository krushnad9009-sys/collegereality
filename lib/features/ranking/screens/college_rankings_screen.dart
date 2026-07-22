import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../providers/ranking_provider.dart';
import '../utils/college_ranking_utils.dart';

class CollegeRankingsScreen extends ConsumerWidget {
  const CollegeRankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(rankingFilterProvider);
    final rankedAsync = ref.watch(rankedCollegesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Rankings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: RankingConstants.rankCategories.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(RankingConstants.rankCategoryLabel(c)),
                    selected: filters.category == c,
                    onSelected: (_) =>
                        ref.read(rankingFilterProvider.notifier).setCategory(c),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AsyncStateView(
              value: rankedAsync,
              onRetry: () => ref.invalidate(rankedCollegesProvider),
              showSkeleton: true,
              isEmpty: (entries) => entries.isEmpty,
              emptyBuilder: () => AsyncEmptyView(
                icon: Icons.leaderboard_outlined,
                title: 'No colleges found for this filter',
                subtitle: 'Try a different ranking category or state filter.',
              ),
              builder: (entries) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final entry = entries[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          '#${entry.rank}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                        title: Text(
                          entry.college.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${entry.college.city}, ${entry.college.state} · ${entry.college.type}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${formatScore(entry.overallScore)}/100',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              formatFees(entry.college),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push(
                          RouteNames.collegeDetailsPath(entry.college.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
