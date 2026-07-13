import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../models/engagement_models.dart';
import '../providers/engagement_provider.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Alert Preferences'),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Choose which alerts you receive',
              style: GoogleFonts.poppins(color: AppTheme.gray600),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable all alerts'),
              value: prefs.alertsEnabled,
              onChanged: (v) => _update(ref, prefs.copyWith(alertsEnabled: v)),
            ),
            const Divider(),
            _sectionTitle('Reviews & Q&A'),
            _toggle(ref, prefs, 'New review on saved college', prefs.newReview,
                (v) => prefs.copyWith(newReview: v)),
            _toggle(ref, prefs, 'New answer to my question', prefs.newAnswer,
                (v) => prefs.copyWith(newAnswer: v)),
            _toggle(ref, prefs, 'New chat message', prefs.newChatMessage,
                (v) => prefs.copyWith(newChatMessage: v)),
            const Divider(),
            _sectionTitle('College & Placements'),
            _toggle(ref, prefs, 'College updates', prefs.collegeUpdates,
                (v) => prefs.copyWith(collegeUpdates: v)),
            _toggle(ref, prefs, 'Placement updates', prefs.placementUpdates,
                (v) => prefs.copyWith(placementUpdates: v)),
            _toggle(ref, prefs, 'Fees change', prefs.feesChange,
                (v) => prefs.copyWith(feesChange: v)),
            _toggle(ref, prefs, 'Placement stats change', prefs.placementStatsChange,
                (v) => prefs.copyWith(placementStatsChange: v)),
            const Divider(),
            _sectionTitle('Scholarships & Admission'),
            _toggle(ref, prefs, 'Scholarship updates', prefs.scholarshipUpdates,
                (v) => prefs.copyWith(scholarshipUpdates: v)),
            _toggle(ref, prefs, 'Scholarship opens', prefs.scholarshipOpen,
                (v) => prefs.copyWith(scholarshipOpen: v)),
            _toggle(ref, prefs, 'Admission reminders', prefs.admissionReminders,
                (v) => prefs.copyWith(admissionReminders: v)),
            _toggle(ref, prefs, 'Admission start', prefs.admissionStart,
                (v) => prefs.copyWith(admissionStart: v)),
            _toggle(ref, prefs, 'Admission deadline', prefs.admissionDeadline,
                (v) => prefs.copyWith(admissionDeadline: v)),
            const Divider(),
            _sectionTitle('Events'),
            _toggle(ref, prefs, 'Event reminders', prefs.eventReminders,
                (v) => prefs.copyWith(eventReminders: v)),
            _toggle(ref, prefs, 'New campus events', prefs.newEvent,
                (v) => prefs.copyWith(newEvent: v)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  Widget _toggle(
    WidgetRef ref,
    NotificationPreferencesModel prefs,
    String title,
    bool value,
    NotificationPreferencesModel Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value && prefs.alertsEnabled,
      onChanged: prefs.alertsEnabled ? (v) => _update(ref, onChanged(v)) : null,
    );
  }

  void _update(WidgetRef ref, NotificationPreferencesModel prefs) {
    ref.read(engagementRepositoryProvider).updatePreferences(prefs);
  }
}
