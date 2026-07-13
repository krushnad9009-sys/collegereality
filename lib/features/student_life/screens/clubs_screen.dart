import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_life_provider.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(filteredClubsProvider);
    final filters = ref.watch(clubFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('College Clubs'),
      ),
      body: clubsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search clubs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (q) =>
                  ref.read(clubFilterProvider.notifier).update(filters.copyWith(searchQuery: q)),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filters.clubType == null,
                    onSelected: (_) => ref
                        .read(clubFilterProvider.notifier)
                        .update(filters.copyWith(clearType: true)),
                  ),
                  ...StudentLifeConstants.clubTypes.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(StudentLifeConstants.clubTypeLabel(type)),
                        selected: filters.clubType == type,
                        onSelected: (_) => ref
                            .read(clubFilterProvider.notifier)
                            .update(filters.copyWith(clubType: type)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(child: Text('No clubs found'))
            else
              ...items.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(c.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${StudentLifeConstants.clubTypeLabel(c.clubType)} · ${c.collegeName}\n'
                      '${c.membersCount} members',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RouteNames.studentLifeClubDetailPath(c.id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClubDetailScreen extends ConsumerWidget {
  final String clubId;

  const ClubDetailScreen({required this.clubId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubByIdProvider(clubId));
    final joinStatuses = ref.watch(clubJoinStatusesProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Club Details'),
      ),
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (club) {
          if (club == null) return const Center(child: Text('Club not found'));

          final joinStatus = joinStatuses[club.id];
          final hasRequested = joinStatus != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(club.name,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(StudentLifeConstants.clubTypeLabel(club.clubType),
                  style: GoogleFonts.poppins(color: AppTheme.gray500)),
              Text(club.collegeName,
                  style: GoogleFonts.poppins(color: AppTheme.gray500, fontSize: 13)),
              const SizedBox(height: 8),
              Text('${club.membersCount} members',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              if (club.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('About', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(club.description,
                    style: GoogleFonts.poppins(height: 1.5, color: AppTheme.gray700)),
              ],
              const SizedBox(height: 16),
              _section('Faculty Coordinator', club.facultyCoordinator),
              if (club.studentCoordinators.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Student Coordinators',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ...club.studentCoordinators.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $s', style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: hasRequested
                    ? null
                    : () => _requestJoin(ref, context, club.id),
                child: Text(
                  joinStatus == StudentLifeConstants.joinStatusPending
                      ? 'Join Request Pending'
                      : joinStatus == StudentLifeConstants.joinStatusApproved
                          ? 'Member'
                          : 'Request to Join',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray700)),
      ],
    );
  }

  Future<void> _requestJoin(WidgetRef ref, BuildContext context, String clubId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(studentLifeRepositoryProvider).requestJoinClub(user.uid, clubId);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Join request submitted');
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }
}
