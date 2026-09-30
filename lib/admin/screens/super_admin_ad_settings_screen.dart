import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../core/ads/ad_remote_settings.dart';
import '../../core/widgets/index.dart';
import '../../features/admin/services/admin_action_logger.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';

DocumentReference<Map<String, dynamic>> get _settingsDoc => FirebaseFirestore
    .instance
    .collection(AdRemoteSettings.collection)
    .doc(AdRemoteSettings.docId);

final _adSettingsProvider = StreamProvider.autoDispose<AdRemoteSettings>((ref) {
  return _settingsDoc.snapshots().map(
        (s) => AdRemoteSettings.fromJson(s.data()),
      );
});

/// Super Admin -> "Manage Advertisements": switch Google AdMob banner /
/// full-screen / rewarded ads on or off for every user, and set the live
/// ad unit IDs -- applied within seconds, no app update. Writes
/// `app_config/ads_settings` (Super Admin-only in firestore.rules).
class SuperAdminAdSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminAdSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminAdSettingsScreen> createState() =>
      _SuperAdminAdSettingsScreenState();
}

class _SuperAdminAdSettingsScreenState
    extends ConsumerState<SuperAdminAdSettingsScreen> {
  AdRemoteSettings? _saved;
  bool _banner = false;
  bool _interstitial = false;
  bool _rewarded = false;
  final _ids = <String, TextEditingController>{
    for (final k in [
      'bannerAdId',
      'bannerAdIdIos',
      'interstitialAdId',
      'interstitialAdIdIos',
      'rewardedAdId',
      'rewardedAdIdIos',
    ])
      k: TextEditingController(),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _ids.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(AdRemoteSettings s) {
    _saved = s;
    _banner = s.enableBannerAds;
    _interstitial = s.enableInterstitialAds;
    _rewarded = s.enableRewardedAds;
    final json = s.toJson();
    for (final e in _ids.entries) {
      e.value.text = json[e.key] as String? ?? '';
    }
  }

  AdRemoteSettings get _draft => AdRemoteSettings(
        enableBannerAds: _banner,
        enableInterstitialAds: _interstitial,
        enableRewardedAds: _rewarded,
        bannerAdId: _ids['bannerAdId']!.text.trim(),
        bannerAdIdIos: _ids['bannerAdIdIos']!.text.trim(),
        interstitialAdId: _ids['interstitialAdId']!.text.trim(),
        interstitialAdIdIos: _ids['interstitialAdIdIos']!.text.trim(),
        rewardedAdId: _ids['rewardedAdId']!.text.trim(),
        rewardedAdIdIos: _ids['rewardedAdIdIos']!.text.trim(),
      );

  bool get _allIdsValid => _ids.values
      .every((c) => AdRemoteSettings.isValidAdUnitId(c.text.trim()));

  bool get _dirty => _saved != null && _draft != _saved;

  Future<void> _save() async {
    if (!_allIdsValid) return;
    setState(() => _saving = true);
    final draft = _draft;
    try {
      await _settingsDoc.set({
        ...draft.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      try {
        await AdminActionLogger().log(
          action: 'ads.settings.update',
          targetId: AdRemoteSettings.docId,
          targetType: AdRemoteSettings.collection,
          metadata: draft.toJson(),
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() => _saved = draft);
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Ad settings saved — live for all users within seconds.',
      );
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: 'Could not save: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_adSettingsProvider);
    final live = async.valueOrNull;
    if (live != null && _saved == null) _hydrate(live);
    final tokens = context.tokens;

    return AdminShellLayout(
      title: 'Manage Advertisements',
      showBack: false,
      isAdminUser: true,
      child: _saved == null
          ? Center(
              child: async.hasError
                  ? Text('Could not load settings: ${async.error}')
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Google AdMob ads in the mobile app. Switches and ad unit '
                  'IDs apply to every user within seconds — no app update '
                  'needed. Debug builds always show Google test ads, '
                  'whatever IDs are set here. Leave an ID empty to use the '
                  "one built into the app (if any). In-house promo banners "
                  'are managed separately under "Promo Ads".',
                  style: AppFonts.plusJakarta(
                      fontSize: 13, color: tokens.textSecondary),
                ),
                const SizedBox(height: 16),
                _FormatCard(
                  title: 'Banner ads',
                  subtitle: 'Sticky banner above the bottom bar on Home and '
                      'College Search.',
                  enabled: _banner,
                  onToggle: (v) => setState(() => _banner = v),
                  androidId: _ids['bannerAdId']!,
                  iosId: _ids['bannerAdIdIos']!,
                  onEdited: () => setState(() {}),
                ),
                _FormatCard(
                  title: 'Full-screen (interstitial) ads',
                  subtitle: 'After a review is submitted / a call ends. At '
                      'most one every 3 minutes, never mid-call.',
                  enabled: _interstitial,
                  onToggle: (v) => setState(() => _interstitial = v),
                  androidId: _ids['interstitialAdId']!,
                  iosId: _ids['interstitialAdIdIos']!,
                  onEdited: () => setState(() {}),
                ),
                _FormatCard(
                  title: 'Rewarded video ads',
                  subtitle: '"Watch a video, get wallet credit" on the Call '
                      'Wallet. Credit is granted by the server-side '
                      'verification callback set on this ad unit in AdMob.',
                  enabled: _rewarded,
                  onToggle: (v) => setState(() => _rewarded = v),
                  androidId: _ids['rewardedAdId']!,
                  iosId: _ids['rewardedAdIdIos']!,
                  onEdited: () => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: _dirty ? 'Save changes' : 'Saved',
                        isLoading: _saving,
                        onPressed: _dirty && _allIdsValid ? _save : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _dirty && !_saving
                          ? () => setState(() => _hydrate(_saved!))
                          : null,
                      child: const Text('Discard'),
                    ),
                  ],
                ),
                if (live?.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Last changed ${live!.updatedAt!.toLocal()}',
                      style: AppFonts.plusJakarta(
                          fontSize: 12, color: tokens.textTertiary),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController androidId;
  final TextEditingController iosId;
  final VoidCallback onEdited;

  const _FormatCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.androidId,
    required this.iosId,
    required this.onEdited,
  });

  String? _error(String value) => AdRemoteSettings.isValidAdUnitId(value.trim())
      ? null
      : 'Format: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final noIds = androidId.text.trim().isEmpty && iosId.text.trim().isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                style: AppFonts.plusJakarta(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              subtitle: Text(subtitle),
              value: enabled,
              onChanged: onToggle,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: androidId,
              onChanged: (_) => onEdited(),
              decoration: InputDecoration(
                labelText: 'Android ad unit ID',
                hintText: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
                errorText: _error(androidId.text),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iosId,
              onChanged: (_) => onEdited(),
              decoration: InputDecoration(
                labelText: 'iOS ad unit ID',
                hintText: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
                errorText: _error(iosId.text),
                border: const OutlineInputBorder(),
              ),
            ),
            if (enabled && noIds)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'On, but no ID set here: release builds show this format '
                  'only if an ID was built into the app.',
                  style: AppFonts.plusJakarta(
                      fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
