import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../admission/providers/admission_provider.dart';
import '../../careers/providers/careers_provider.dart';
import '../../colleges/providers/college_provider.dart';
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
      return const Center(child: Text('No saved colleges'));
    }

    return collegesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
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
          itemBuilder: (_, i) => _BookmarkTile(
            title: saved[i].name,
            subtitle: '${saved[i].city}, ${saved[i].state}',
            onTap: () => context.push(RouteNames.collegeDetailsPath(saved[i].id)),
          ),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final saved = all.where((s) => savedIds.contains(s.id)).toList();
        if (saved.isEmpty) return const Center(child: Text('No saved scholarships'));
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final saved = all.where((e) => savedIds.contains(e.id)).toList();
        if (saved.isEmpty) return const Center(child: Text('No saved exams'));
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final saved = all.where((i) => savedIds.contains(i.id)).toList();
        if (saved.isEmpty) return const Center(child: Text('No saved internships'));
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final saved = all.where((j) => savedIds.contains(j.id)).toList();
        if (saved.isEmpty) return const Center(child: Text('No saved jobs'));
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
      return const Center(child: Text('No saved questions'));
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
      loading: () => const ListTile(title: Text('Loading...')),
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
  final VoidCallback onTap;

  const _BookmarkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.bookmark, color: AppTheme.primaryColor),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
