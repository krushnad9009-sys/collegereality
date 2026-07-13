import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/student_life_constants.dart';
import '../providers/student_life_provider.dart';

class CompetitionsScreen extends ConsumerWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compsAsync = ref.watch(filteredCompetitionsProvider);
    final filters = ref.watch(competitionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Competitions'),
      ),
      body: compsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search competitions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (q) => ref
                  .read(competitionFilterProvider.notifier)
                  .update(filters.copyWith(searchQuery: q)),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filters.scope == null,
                    onSelected: (_) => ref
                        .read(competitionFilterProvider.notifier)
                        .update(filters.copyWith(clearScope: true)),
                  ),
                  ...[
                    StudentLifeConstants.scopeCollege,
                    StudentLifeConstants.scopeInterCollege,
                    StudentLifeConstants.scopeNational,
                  ].map(
                    (scope) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(StudentLifeConstants.competitionScopeLabel(scope)),
                        selected: filters.scope == scope,
                        onSelected: (_) => ref
                            .read(competitionFilterProvider.notifier)
                            .update(filters.copyWith(scope: scope)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Open registration only', style: GoogleFonts.poppins(fontSize: 14)),
              value: filters.openOnly,
              onChanged: (v) => ref
                  .read(competitionFilterProvider.notifier)
                  .update(filters.copyWith(openOnly: v)),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Center(child: Text('No competitions found'))
            else
              ...items.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(c.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${StudentLifeConstants.competitionScopeLabel(c.scope)} · ${c.collegeName}\n'
                      'Deadline: ${DateFormat('d MMM yyyy').format(c.registrationDeadline)}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RouteNames.studentLifeCompetitionDetailPath(c.id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CompetitionDetailScreen extends ConsumerWidget {
  final String competitionId;

  const CompetitionDetailScreen({required this.competitionId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(competitionByIdProvider(competitionId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Competition'),
      ),
      body: compAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (comp) {
          if (comp == null) return const Center(child: Text('Competition not found'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(comp.title,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${StudentLifeConstants.competitionScopeLabel(comp.scope)} · ${comp.collegeName}',
                style: GoogleFonts.poppins(color: AppTheme.gray500, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                comp.isRegistrationOpen ? 'Registration Open' : 'Registration Closed',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: comp.isRegistrationOpen ? AppTheme.accentColor : AppTheme.warningColor,
                ),
              ),
              Text(
                'Deadline: ${DateFormat('d MMM yyyy').format(comp.registrationDeadline)}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              if (comp.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('About', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                Text(comp.description,
                    style: GoogleFonts.poppins(height: 1.5, color: AppTheme.gray700)),
              ],
              if (comp.prizeDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Prize Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                Text(comp.prizeDetails,
                    style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ],
              if (comp.winners.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Winners', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ...comp.winners.map(
                  (w) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.emoji_events, color: AppTheme.warningColor, size: 20),
                    title: Text(w.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('${w.position}${w.collegeName.isNotEmpty ? ' · ${w.collegeName}' : ''}'),
                  ),
                ),
              ],
              if (comp.certificateUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Certificates', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ...comp.certificateUrls.map(
                  (url) => TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(url)),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('View Certificate'),
                  ),
                ),
              ],
              if (comp.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Photos', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: comp.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: comp.photoUrls[i],
                        width: 120,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              if (comp.videoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Videos', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ...comp.videoUrls.map(
                  (url) => TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(url)),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Watch Video'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
