import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../services/admin_ads_service.dart';
import '../utils/admin_permissions.dart';
import '../widgets/admin_shell_layout.dart';

class AdminAdsScreen extends ConsumerStatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  ConsumerState<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends ConsumerState<AdminAdsScreen> {
  Future<void> _editAd([AdminAdModel? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final ctaLabel = TextEditingController(text: existing?.ctaLabel ?? 'Learn more');
    final ctaUrl = TextEditingController(text: existing?.ctaUrl ?? '');
    var isActive = existing?.isActive ?? true;
    var priority = existing?.priority ?? 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New advertisement' : 'Edit advertisement'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: body,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Body',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrl,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctaLabel,
                    decoration: const InputDecoration(
                      labelText: 'CTA label',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctaUrl,
                    decoration: const InputDecoration(
                      labelText: 'CTA URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                  ),
                  Row(
                    children: [
                      const Text('Priority'),
                      Expanded(
                        child: Slider(
                          value: priority.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$priority',
                          onChanged: (v) => setLocal(() => priority = v.round()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final ad = AdminAdModel(
      id: existing?.id ?? '',
      title: title.text.trim(),
      body: body.text.trim(),
      imageUrl: imageUrl.text.trim(),
      ctaLabel: ctaLabel.text.trim().isEmpty ? 'Learn more' : ctaLabel.text.trim(),
      ctaUrl: ctaUrl.text.trim(),
      isActive: isActive,
      priority: priority,
      updatedAt: DateTime.now(),
    );
    await ref.read(adminAdsServiceProvider).upsertAd(ad);
    ref.invalidate(adminAdsProvider);
    ref.invalidate(activeHomeAdsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentUserModelProvider).valueOrNull;
    final canManage = AdminPermissions.canManageAds(actor?.userType);
    final adsAsync = ref.watch(adminAdsProvider);

    return AdminShellLayout(
      title: 'Ads & Promotions',
      isAdminUser: true,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _editAd(),
              icon: const Icon(Icons.add),
              label: const Text('New ad'),
            )
          : null,
      child: !canManage
          ? const Center(child: Text('Only Super Admins can manage ads.'))
          : adsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (ads) {
                if (ads.isEmpty) {
                  return Center(
                    child: Text(
                      'No advertisements yet',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.gray600),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: ads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          ad.title,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${ad.isCurrentlyLive ? 'Live' : 'Inactive'} · priority ${ad.priority}\n${ad.body}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _editAd(ad),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                await ref.read(adminAdsServiceProvider).deleteAd(ad.id);
                                ref.invalidate(adminAdsProvider);
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
