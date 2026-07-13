import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/ecosystem_constants.dart';
import '../providers/ecosystem_provider.dart';

/// Official notices and content on college detail overview.
class OfficialCollegeContentSection extends ConsumerWidget {
  final String collegeId;

  const OfficialCollegeContentSection({required this.collegeId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(
      collegeOfficialContentProvider((collegeId: collegeId, section: null)),
    );
    final workshopsAsync = ref.watch(collegeFacultyWorkshopsProvider(collegeId));
    final mentorshipAsync = ref.watch(collegeMentorshipOffersProvider(collegeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        contentAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Updates',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...items.take(5).map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.verified,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          title: Text(
                            item.title,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${EcosystemConstants.sectionLabel(item.section)} · ${item.body}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        workshopsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (workshops) {
            if (workshops.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faculty Workshops',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...workshops.take(3).map(
                      (w) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(w.title),
                          subtitle: Text(w.description),
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        mentorshipAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (offers) {
            if (offers.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alumni Mentorship',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...offers.take(3).map(
                      (o) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(o.topic),
                          subtitle: Text('${o.alumniName} · ${o.description}'),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}
