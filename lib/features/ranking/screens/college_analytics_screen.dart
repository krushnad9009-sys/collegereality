import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../models/ranking_models.dart';
import '../providers/ranking_provider.dart';

class CollegeAnalyticsScreen extends ConsumerWidget {
  const CollegeAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(collegeAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(title: 'Popular Colleges', entries: snapshot.popularColleges),
            _Section(title: 'Most Reviewed', entries: snapshot.mostReviewed),
            _Section(title: 'Highest Rated', entries: snapshot.highestRated),
            _Section(title: 'Most Searched', entries: snapshot.mostSearched),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<CollegeAnalyticsEntry> entries;

  const _Section({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text('No data', style: GoogleFonts.poppins(color: AppTheme.gray500))
        else
          ...entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(e.college.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text('${e.college.city}, ${e.college.state}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${e.metricValue}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      Text(e.metricLabel,
                          style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.gray500)),
                    ],
                  ),
                  onTap: () => context.push(RouteNames.collegeDetailsPath(e.college.id)),
                ),
              )),
        const SizedBox(height: 20),
      ],
    );
  }
}
