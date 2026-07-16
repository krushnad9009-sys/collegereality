import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/student_life_models.dart';
import '../providers/student_life_provider.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredEventsProvider);
    final filters = ref.watch(eventFilterProvider);
    final savedIds = ref.watch(savedEventIdsProvider).valueOrNull ?? {};
    final registeredIds = ref.watch(registeredEventIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('College Events'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (q) =>
                  ref.read(eventFilterProvider.notifier).update(filters.copyWith(searchQuery: q)),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filters.category == null,
                    onSelected: (_) => ref
                        .read(eventFilterProvider.notifier)
                        .update(filters.copyWith(clearCategory: true)),
                  ),
                  ...StudentLifeConstants.eventCategories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(StudentLifeConstants.eventCategoryLabel(cat)),
                        selected: filters.category == cat,
                        onSelected: (_) => ref
                            .read(eventFilterProvider.notifier)
                            .update(filters.copyWith(category: cat)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Upcoming only', style: GoogleFonts.poppins(fontSize: 14)),
              value: filters.upcomingOnly,
              onChanged: (v) =>
                  ref.read(eventFilterProvider.notifier).update(filters.copyWith(upcomingOnly: v)),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Center(child: Text('No events found'))
            else
              ...items.map(
                (e) => _EventCard(
                  event: e,
                  isSaved: savedIds.contains(e.id),
                  isRegistered: registeredIds.contains(e.id),
                  onTap: () => context.push(RouteNames.studentLifeEventDetailPath(e.id)),
                  onSave: () => _toggleSave(ref, context, e.id, savedIds.contains(e.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave(
    WidgetRef ref,
    BuildContext context,
    String id,
    bool isSaved,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final repo = ref.read(studentLifeRepositoryProvider);
    try {
      if (isSaved) {
        await repo.unsaveEvent(user.uid, id);
      } else {
        await repo.saveEvent(user.uid, id);
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }
}

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    final savedIds = ref.watch(savedEventIdsProvider).valueOrNull ?? {};
    final registeredIds = ref.watch(registeredEventIdsProvider).valueOrNull ?? {};
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareEvent(context, eventId),
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (event) {
          if (event == null) return const Center(child: Text('Event not found'));

          final isSaved = savedIds.contains(event.id);
          final isRegistered = registeredIds.contains(event.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (event.posterUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: event.posterUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      height: 200,
                      color: AppTheme.gray100,
                      child: const Icon(Icons.event, size: 48),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(event.title,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(event.collegeName,
                  style: GoogleFonts.poppins(color: AppTheme.gray500, fontSize: 13)),
              const SizedBox(height: 8),
              _badge(StudentLifeConstants.eventCategoryLabel(event.category)),
              const SizedBox(height: 12),
              _info(Icons.calendar_today, dateFmt.format(event.startAt)),
              _info(Icons.schedule, 'Ends: ${dateFmt.format(event.endAt)}'),
              _info(Icons.location_on_outlined, event.location),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('About', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(event.description,
                    style: GoogleFonts.poppins(height: 1.5, color: AppTheme.gray700)),
              ],
              if (event.galleryUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Event Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: event.galleryUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: event.galleryUrls[i],
                        width: 120,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: isRegistered
                          ? null
                          : () => _register(ref, context, event.id),
                      child: Text(isRegistered ? 'Registered' : 'Register'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _toggleSave(ref, context, event.id, isSaved),
                    child: Text(isSaved ? 'Saved' : 'Save'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.gray500),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
    );
  }

  Future<void> _register(WidgetRef ref, BuildContext context, String eventId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(studentLifeRepositoryProvider).registerForEvent(user.uid, eventId);
      if (context.mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Registered successfully');
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  Future<void> _toggleSave(
    WidgetRef ref,
    BuildContext context,
    String id,
    bool isSaved,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final repo = ref.read(studentLifeRepositoryProvider);
    try {
      if (isSaved) {
        await repo.unsaveEvent(user.uid, id);
      } else {
        await repo.saveEvent(user.uid, id);
      }
    } catch (e) {
      if (context.mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  void _shareEvent(BuildContext context, String eventId) {
    final link = RouteNames.studentLifeEventDetailPath(eventId);
    Clipboard.setData(ClipboardData(text: link));
    SnackBarHelper.showSuccessSnackBar(context, message: 'Event link copied to clipboard');
  }
}

class _EventCard extends StatelessWidget {
  final CampusEventModel event;
  final bool isSaved;
  final bool isRegistered;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _EventCard({
    required this.event,
    required this.isSaved,
    required this.isRegistered,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM · h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(event.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  IconButton(
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                    onPressed: onSave,
                  ),
                ],
              ),
              Text(
                '${StudentLifeConstants.eventCategoryLabel(event.category)} · ${event.collegeName}',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
              ),
              const SizedBox(height: 4),
              Text(dateFmt.format(event.startAt),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryColor)),
              if (event.location.isNotEmpty)
                Text(event.location,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600)),
              if (isRegistered)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Registered',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
