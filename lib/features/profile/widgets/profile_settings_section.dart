import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/premium_list_row.dart';

/// App preferences: theme, legal links, notifications.
class ProfileSettingsSection extends ConsumerWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final themeMode = ref.watch(themeModeProvider);

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppFonts.plusJakarta(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Appearance, notifications, and legal',
            style: AppFonts.plusJakarta(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Theme',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_rounded, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined, size: 16),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              ref.read(themeModeProvider.notifier).state = selection.first;
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PremiumListRow(
            leadingIcon: Icons.notifications_outlined,
            title: 'Notification preferences',
            dense: true,
            onTap: () => context.push(RouteNames.notificationPreferences),
          ),
          PremiumListRow(
            leadingIcon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            dense: true,
            onTap: () => context.push(RouteNames.privacyPolicy),
          ),
          PremiumListRow(
            leadingIcon: Icons.description_outlined,
            title: 'Terms of service',
            dense: true,
            onTap: () => context.push(RouteNames.termsOfService),
          ),
        ],
      ),
    );
  }
}
