import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../models/engagement_models.dart';
import '../providers/engagement_provider.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Alert Preferences',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: tokens.textPrimary,
          ),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView.fromError(e),
        data: (prefs) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Choose which alerts you receive',
              style: AppFonts.plusJakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumCard(
              radius: tokens.buttonRadius,
              padding: EdgeInsets.zero,
              child: _ToggleTile(
                title: 'Enable all alerts',
                subtitle: 'Master switch for every notification below',
                value: prefs.alertsEnabled,
                onChanged: (v) => _update(ref, prefs.copyWith(alertsEnabled: v)),
                emphasized: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'Reviews & Q&A'),
            _ToggleGroup(
              children: [
                _ToggleTile(
                  title: 'New review on saved college',
                  value: prefs.newReview && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(newReview: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'New answer to my question',
                  value: prefs.newAnswer && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(newAnswer: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'New chat message',
                  value: prefs.newChatMessage && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(newChatMessage: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Review approved',
                  value: prefs.reviewApproved && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(reviewApproved: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Review interactions',
                  value: prefs.reviewInteraction && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(reviewInteraction: v))
                      : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'Verification & Community'),
            _ToggleGroup(
              children: [
                _ToggleTile(
                  title: 'Verification updates',
                  value: prefs.verificationUpdates && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(verificationUpdates: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Community posts & comments',
                  value: prefs.communityUpdates && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(communityUpdates: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Admin announcements',
                  value: prefs.adminAnnouncements && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(adminAnnouncements: v))
                      : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'College & Placements'),
            _ToggleGroup(
              children: [
                _ToggleTile(
                  title: 'College updates',
                  value: prefs.collegeUpdates && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(collegeUpdates: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Placement updates',
                  value: prefs.placementUpdates && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(placementUpdates: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Fees change',
                  value: prefs.feesChange && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(feesChange: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Placement stats change',
                  value: prefs.placementStatsChange && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(placementStatsChange: v))
                      : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'Scholarships & Admission'),
            _ToggleGroup(
              children: [
                _ToggleTile(
                  title: 'Scholarship updates',
                  value: prefs.scholarshipUpdates && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(scholarshipUpdates: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Scholarship opens',
                  value: prefs.scholarshipOpen && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(scholarshipOpen: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Admission reminders',
                  value: prefs.admissionReminders && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(admissionReminders: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Admission start',
                  value: prefs.admissionStart && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(admissionStart: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Admission deadline',
                  value: prefs.admissionDeadline && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(admissionDeadline: v))
                      : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'Careers'),
            _ToggleGroup(
              children: [
                _ToggleTile(
                  title: 'New job listings',
                  value: prefs.newJob && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(newJob: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'New internship listings',
                  value: prefs.newInternship && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(newInternship: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'Application status updates',
                  value: prefs.applicationUpdate && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(applicationUpdate: v))
                      : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'Events'),
            _ToggleGroup(
              children: [
                _ToggleTile(
                  title: 'Event reminders',
                  value: prefs.eventReminders && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(eventReminders: v))
                      : null,
                ),
                _ToggleTile(
                  title: 'New campus events',
                  value: prefs.newEvent && prefs.alertsEnabled,
                  onChanged: prefs.alertsEnabled
                      ? (v) => _update(ref, prefs.copyWith(newEvent: v))
                      : null,
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _update(WidgetRef ref, NotificationPreferencesModel prefs) {
    ref.read(engagementRepositoryProvider).updatePreferences(prefs);
  }
}

/// Card wrapper that lays out a set of [_ToggleTile]s with hairline
/// dividers between them, matching the app's premium settings-list look.
class _ToggleGroup extends StatelessWidget {
  final List<Widget> children;

  const _ToggleGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.buttonRadius,
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

/// A single preference row: title (+ optional subtitle) and a trailing
/// switch, with a hairline divider unless it's the last row in its group.
class _ToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLast;
  final bool emphasized;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.isLast = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final disabled = onChanged == null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppFonts.plusJakarta(
                        fontSize: emphasized ? 15 : 14,
                        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                        color: disabled ? tokens.textTertiary : tokens.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppFonts.plusJakarta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: primary,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: tokens.borderSubtle),
      ],
    );
  }
}
