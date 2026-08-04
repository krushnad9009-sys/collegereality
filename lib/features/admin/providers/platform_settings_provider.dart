import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/services/super_admin_settings_service.dart';

/// Platform settings consumed by the main app (banner, announcement, taxonomy).
final platformSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await ref.watch(superAdminSettingsServiceProvider).loadSettings();
  } catch (_) {
    return const {};
  }
});

final platformAnnouncementProvider = Provider<String>((ref) {
  final settings = ref.watch(platformSettingsProvider).valueOrNull ?? const {};
  return settings['globalAnnouncement']?.toString().trim() ?? '';
});

final platformHomeBannerUrlProvider = Provider<String>((ref) {
  final settings = ref.watch(platformSettingsProvider).valueOrNull ?? const {};
  return settings['homeBannerUrl']?.toString().trim() ?? '';
});
