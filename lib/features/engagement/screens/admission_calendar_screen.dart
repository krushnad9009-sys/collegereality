import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/engagement_constants.dart';
import '../models/engagement_models.dart';
import '../providers/engagement_provider.dart';

class AdmissionCalendarScreen extends ConsumerWidget {
  const AdmissionCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(filteredCalendarProvider);
    final filters = ref.watch(calendarFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Admission Calendar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search dates, CAP rounds, counselling...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (q) =>
                  ref.read(calendarFilterProvider.notifier).setSearch(q),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filters.category == null,
                  onSelected: (_) =>
                      ref.read(calendarFilterProvider.notifier).setCategory(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Upcoming'),
                  selected: filters.upcomingOnly,
                  onSelected: (v) =>
                      ref.read(calendarFilterProvider.notifier).setUpcomingOnly(v),
                ),
                ...[
                  EngagementConstants.calendarCapRound,
                  EngagementConstants.calendarCounselling,
                  EngagementConstants.calendarDocVerification,
                  EngagementConstants.calendarSeatAllotment,
                  EngagementConstants.calendarFeePayment,
                  EngagementConstants.calendarHostelAdmission,
                ].map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(EngagementConstants.calendarCategoryLabel(c)),
                      selected: filters.category == c,
                      onSelected: (_) =>
                          ref.read(calendarFilterProvider.notifier).setCategory(c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      'No calendar events found',
                      style: GoogleFonts.poppins(color: AppTheme.gray500),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CalendarCard(event: events[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final AdmissionCalendarEventModel event;

  const _CalendarCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final categoryLabel = EngagementConstants.calendarCategoryLabel(event.category);
    final isUrgent = event.isDeadlineSoon;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Soon',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            if (event.state.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.state,
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 6),
                Text(
                  dateFmt.format(event.eventDate),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
                ),
              ],
            ),
            if (event.deadlineDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.errorColor),
                  const SizedBox(width: 6),
                  Text(
                    'Deadline: ${dateFmt.format(event.deadlineDate!)}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
                  ),
                ],
              ),
            ],
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                event.description,
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray600, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
