import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../widgets/profile_settings_section.dart';

/// App-level preferences: appearance, notifications, and legal documents.
/// Reached from the Profile hub via "App Settings".
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.lg,
          AppSpacing.pageH,
          AppSpacing.section,
        ),
        child: ProfileSettingsSection(),
      ),
    );
  }
}
