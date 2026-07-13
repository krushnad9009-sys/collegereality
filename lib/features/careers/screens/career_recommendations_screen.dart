import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/careers_provider.dart';

class CareerRecommendationsScreen extends ConsumerWidget {
  const CareerRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(recommendedJobsProvider);
    final internshipsAsync = ref.watch(recommendedInternshipsProvider);
    final suggestionsAsync = ref.watch(careerSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Career Matches'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('AI Career Suggestions',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          suggestionsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (tips) => Column(
              children: tips
                  .map(
                    (t) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                        title: Text(t, style: GoogleFonts.poppins(fontSize: 13)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Jobs for your degree',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (matches) {
              if (matches.isEmpty) {
                return Text('Complete your profile to get job matches.',
                    style: GoogleFonts.poppins(color: AppTheme.gray500));
              }
              return Column(
                children: matches
                    .map(
                      (m) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(m.item.title,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text('${m.item.companyName} · ${m.reason}',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          trailing: Text('${m.score}%'),
                          onTap: () => context.push(RouteNames.careersJobs),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Internships for your skills',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          internshipsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (matches) {
              if (matches.isEmpty) {
                return Text('Add skills/interests to get internship matches.',
                    style: GoogleFonts.poppins(color: AppTheme.gray500));
              }
              return Column(
                children: matches
                    .map(
                      (m) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(m.item.title,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text('${m.item.companyName} · ${m.reason}',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          trailing: Text('${m.score}%'),
                          onTap: () => context.push(RouteNames.careersInternships),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
