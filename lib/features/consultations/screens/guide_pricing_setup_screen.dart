import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/services/firestore_user_service.dart';
import '../../communication/models/guide_stats_model.dart';

/// Lets a verified guide set chat/call/video prices in whole rupees
/// (converted to paise before writing — Firestore/rules never see a
/// float). Route is only reachable once the "Available as a guide" toggle
/// on the profile screen is on, which is itself gated on verification.
class GuidePricingSetupScreen extends ConsumerStatefulWidget {
  const GuidePricingSetupScreen({super.key});

  @override
  ConsumerState<GuidePricingSetupScreen> createState() =>
      _GuidePricingSetupScreenState();
}

class _GuidePricingSetupScreenState
    extends ConsumerState<GuidePricingSetupScreen> {
  final _userService = FirestoreUserService();
  bool _hydrated = false;
  bool _saving = false;

  bool _chatOn = false;
  final _chatPriceController = TextEditingController(text: '49');
  int _chatDuration = 15;

  bool _callOn = false;
  final _callPriceController = TextEditingController(text: '99');
  int _callDuration = 15;

  bool _videoOn = false;
  final _videoPriceController = TextEditingController(text: '199');
  int _videoDuration = 30;

  @override
  void dispose() {
    _chatPriceController.dispose();
    _callPriceController.dispose();
    _videoPriceController.dispose();
    super.dispose();
  }

  void _hydrate(GuideCommunicationSettings settings) {
    if (_hydrated) return;
    _hydrated = true;
    _chatOn = settings.chatAvailable;
    if (settings.chatPricePaise > 0) {
      _chatPriceController.text = (settings.chatPricePaise / 100).toStringAsFixed(0);
    }
    _chatDuration = settings.chatDurationMinutes;

    final call = settings.callPricing
        .where((o) => o.type == 'call')
        .cast<GuideCallPriceOption?>()
        .firstWhere((_) => true, orElse: () => null);
    if (call != null) {
      _callOn = settings.callAvailable;
      _callPriceController.text = (call.pricePaise / 100).toStringAsFixed(0);
      _callDuration = call.minutes;
    }
    final video = settings.callPricing
        .where((o) => o.type == 'video')
        .cast<GuideCallPriceOption?>()
        .firstWhere((_) => true, orElse: () => null);
    if (video != null) {
      _videoOn = settings.callAvailable && video.pricePaise > 0;
      _videoPriceController.text = (video.pricePaise / 100).toStringAsFixed(0);
      _videoDuration = video.minutes;
    }
  }

  int _rupeesToPaise(TextEditingController c) {
    final rupees = int.tryParse(c.text.trim()) ?? 0;
    return rupees * 100;
  }

  Future<void> _save(String uid, GuideCommunicationSettings current) async {
    setState(() => _saving = true);
    try {
      final options = <GuideCallPriceOption>[
        if (_callOn)
          GuideCallPriceOption(
            type: 'call',
            minutes: _callDuration,
            pricePaise: _rupeesToPaise(_callPriceController),
          ),
        if (_videoOn)
          GuideCallPriceOption(
            type: 'video',
            minutes: _videoDuration,
            pricePaise: _rupeesToPaise(_videoPriceController),
          ),
      ];
      final updated = current.copyWith(
        chatAvailable: _chatOn,
        chatPricePaise: _rupeesToPaise(_chatPriceController),
        chatDurationMinutes: _chatDuration,
        callAvailable: _callOn || _videoOn,
        callPricing: options,
      );
      await _userService.updateUserProfile(uid: uid, communicationSettings: updated);
      if (!mounted) return;
      SnackBarHelper.showSuccessSnackBar(context, message: 'Pricing saved.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat & call prices')),
      body: AsyncStateView(
        value: userAsync,
        builder: (user) {
          if (user == null) {
            return const AsyncEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Not signed in',
              subtitle: 'Sign in to set your consultation prices.',
            );
          }
          _hydrate(user.communicationSettings);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Set your prices',
                  subtitle:
                      'Prospective students pay you directly for a private chat or call. A platform fee applies.',
                ),
                const SizedBox(height: 16),
                _channelTile(
                  title: '💬 Chat',
                  enabled: _chatOn,
                  onToggle: (v) => setState(() => _chatOn = v),
                  priceController: _chatPriceController,
                  duration: _chatDuration,
                  durationOptions: const [15, 30],
                  onDurationChanged: (v) => setState(() => _chatDuration = v),
                ),
                const SizedBox(height: 12),
                _channelTile(
                  title: '📞 Voice call',
                  enabled: _callOn,
                  onToggle: (v) => setState(() => _callOn = v),
                  priceController: _callPriceController,
                  duration: _callDuration,
                  durationOptions: const [15, 30],
                  onDurationChanged: (v) => setState(() => _callDuration = v),
                ),
                const SizedBox(height: 12),
                _channelTile(
                  title: '📹 Video call',
                  enabled: _videoOn,
                  onToggle: (v) => setState(() => _videoOn = v),
                  priceController: _videoPriceController,
                  duration: _videoDuration,
                  durationOptions: const [15, 30, 45],
                  onDurationChanged: (v) => setState(() => _videoDuration = v),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save prices',
                  isLoading: _saving,
                  onPressed: () => _save(user.uid, user.communicationSettings),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _channelTile({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController priceController,
    required int duration,
    required List<int> durationOptions,
    required ValueChanged<int> onDurationChanged,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: duration,
                  items: durationOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onDurationChanged(v);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
