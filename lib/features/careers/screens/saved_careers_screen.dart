import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../providers/careers_provider.dart';

class SavedCareersScreen extends ConsumerWidget {
  const SavedCareersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedInternshipIds = ref.watch(savedInternshipIdsProvider).valueOrNull ?? {};
    final savedJobIds = ref.watch(savedJobIdsProvider).valueOrNull ?? {};
    final internshipsAsync = ref.watch(internshipsProvider);
    final jobsAsync = ref.watch(jobsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Saved'),
          bottom: const TabBar(tabs: [Tab(text: 'Internships'), Tab(text: 'Jobs')]),
        ),
        body: TabBarView(
          children: [
            internshipsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final saved = all.where((i) => savedInternshipIds.contains(i.id)).toList();
                if (saved.isEmpty) return const Center(child: Text('No saved internships'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: saved.length,
                  itemBuilder: (_, i) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(saved[i].title,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('${saved[i].companyName} · ${saved[i].city}',
                          style: GoogleFonts.poppins(fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
            jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final saved = all.where((j) => savedJobIds.contains(j.id)).toList();
                if (saved.isEmpty) return const Center(child: Text('No saved jobs'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: saved.length,
                  itemBuilder: (_, i) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(saved[i].title,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${saved[i].companyName} · ${saved[i].salaryRange}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
