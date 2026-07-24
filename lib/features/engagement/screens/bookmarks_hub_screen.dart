import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../admission/providers/admission_provider.dart';
import '../../careers/providers/careers_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../ranking/widgets/cr_score_badge_widget.dart';
import '../../questions/providers/question_provider.dart';
import '../providers/engagement_provider.dart';

class BookmarksHubScreen extends ConsumerWidget {
  const BookmarksHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Bookmarks'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Colleges'),
              Tab(text: 'Scholarships'),
              Tab(text: 'Exams'),
              Tab(text: 'Internships'),
              Tab(text: 'Jobs'),
              Tab(text: 'Questions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CollegesTab(),
            _ScholarshipsTab(),
            _ExamsTab(),
            _InternshipsTab(),
            _JobsTab(),
            _QuestionsTab(),
          ],
        ),
      ),
    );
  }
}

class _CollegesTab extends ConsumerWidget {
  const _CollegesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteCollegeIdsProvider).valueOrNull ?? {};
    final collegesAsync = ref.watch(savedCollegesProvider);

    if (favoriteIds.isEmpty) {
      return const AsyncEmptyView(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved colleges',
        subtitle: 'Bookmark colleges while browsing to find them here.',
      );
    }

    return collegesAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 6),
      error: (e, _) => AsyncErrorView.fromError(e),
      data: (saved) {
        if (saved.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: favoriteIds.map((id) {
              return _BookmarkTile(
                title: 'Saved college',
                subtitle: id,
                onTap: () => context.push(RouteNames.collegeDetailsPath(id)),
              );
            }).toList(),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: saved.length,
          itemBuilder: (_, i) {
            final college = saved[i];
            final crScore = CrScoreEngine.effectiveScore(college);
            return _BookmarkTile(
            title: college.name,
            subtitle: '${college.city}, ${college.state}',
            trailing: crScore > 0
                ? CrScoreBadgeWidget(score: crScore, fontSize: 11)
                : null,
            onTap: () => context.push(RouteNames.collegeDetailsPath(college.id)),
          );
          },
        );
      },
    );
  }
}

class _ScholarshipsTab extends ConsumerWidget {
  const _ScholarshipsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedScholarshipIdsProvider).valueOrNull ?? {};
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return scholarshipsAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 5),
      error: (e, _) => AsyncErrorView.fromError(e),
      data: (all) {
        final saved = all.where((s) => savedIds.contains(s.id)).toList();
        if (saved.isEmpty) {
          return const AsyncEmptyView(
            icon: Icons.card_giftcard_outlined,
            title: 'No saved scholarships',
            subtitle: 'Save scholarships from the admission hub to track them here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: saved.length,
          itemBuilder: (_, i) => _BookmarkTile(
            title: saved[i].name,
            subtitle: saved[i].providerType,
            onTap: () => context.push(RouteNames.admissionScholarships),
          ),
        );
      },
    );
  }
}

class _ExamsTab extends ConsumerWidget {
  const _ExamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedExamIdsProvider).valueOrNull ?? {};
    final examsAsync = ref.watch(entranceExamsProvider);

    return examsAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 5),
      error: (e, _) => AsyncErrorView.fromError(e),
      data: (all) {
        final saved = all.where((e) => savedIds.contains(e.id)).toList();
        if (saved.isEmpty) {
          return const AsyncEmptyView(
            icon: Icons.edit_note_outlined,
            title: 'No saved exams',
            subtitle: 'Bookmark entrance exams to keep deadlines handy.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: saved.length,
          itemBuilder: (_, i) => _BookmarkTile(
            title: saved[i].name,
            subtitle: saved[i].category,
            onTap: () => context.push(RouteNames.admissionExams),
          ),
        );
      },
    );
  }
}

class _InternshipsTab extends ConsumerWidget {
  const _InternshipsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedInternshipIdsProvider).valueOrNull ?? {};
    final internshipsAsync = ref.watch(internshipsProvider);

    return internshipsAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 5),
      error: (e, _) => AsyncErrorView.fromError(e),
      data: (all) {
        final saved = all.where((i) => savedIds.contains(i.id)).toList();
        if (saved.isEmpty) {
          return const AsyncEmptyView(
            icon: Icons.work_outline_rounded,
            title: 'No saved internships',
            subtitle: 'Save internships from the careers section to revisit later.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: saved.length,
          itemBuilder: (_, i) => _BookmarkTile(
            title: saved[i].title,
            subtitle: '${saved[i].companyName} · ${saved[i].city}',
            onTap: () => context.push(RouteNames.careersInternships),
          ),
        );
      },
    );
  }
}

class _JobsTab extends ConsumerWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedJobIdsProvider).valueOrNull ?? {};
    final jobsAsync = ref.watch(jobsProvider);

    return jobsAsync.when(
      loading: () => const ListSkeletonLoader(itemCount: 5),
      error: (e, _) => AsyncErrorView.fromError(e),
      data: (all) {
        final saved = all.where((j) => savedIds.contains(j.id)).toList();
        if (saved.isEmpty) {
          return const AsyncEmptyView(
            icon: Icons.business_center_outlined,
            title: 'No saved jobs',
            subtitle: 'Bookmark job listings to compare opportunities later.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: saved.length,
          itemBuilder: (_, i) => _BookmarkTile(
            title: saved[i].title,
            subtitle: '${saved[i].companyName} · ${saved[i].salaryRange}',
            onTap: () => context.push(RouteNames.careersJobs),
          ),
        );
      },
    );
  }
}

class _QuestionsTab extends ConsumerWidget {
  const _QuestionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedQuestionIdsProvider).valueOrNull ?? {};

    if (savedIds.isEmpty) {
      return const AsyncEmptyView(
        icon: Icons.help_outline_rounded,
        title: 'No saved questions',
        subtitle: 'Save Q&A threads to review answers anytime.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedIds.length,
      itemBuilder: (_, i) {
        final questionId = savedIds.elementAt(i);
        return _SavedQuestionTile(questionId: questionId);
      },
    );
  }
}

class _SavedQuestionTile extends ConsumerWidget {
  final String questionId;

  const _SavedQuestionTile({required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionByIdProvider(questionId));
    return questionAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: SkeletonBox(height: 72),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (q) {
        if (q == null) return const SizedBox.shrink();
        return _BookmarkTile(
          title: q.title,
          subtitle: q.collegeName,
          onTap: () => context.push(
            RouteNames.collegeQuestionPath(q.collegeId, q.id),
          ),
        );
      },
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _BookmarkTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        radius: tokens.buttonRadius,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: tokens.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
