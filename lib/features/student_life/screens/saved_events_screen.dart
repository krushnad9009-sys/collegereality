import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_theme.dart';
import '../providers/student_life_provider.dart';

class SavedEventsScreen extends ConsumerWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedEventIdsProvider).valueOrNull ?? {};
    final eventsAsync = ref.watch(eventsProvider);
    final dateFmt = DateFormat('d MMM · h:mm a');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Saved Events'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final saved = all.where((e) => savedIds.contains(e.id)).toList();
          if (saved.isEmpty) return const Center(child: Text('No saved events'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: saved.length,
            itemBuilder: (_, i) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(saved[i].title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${saved[i].collegeName} · ${dateFmt.format(saved[i].startAt)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
