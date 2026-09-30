import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/ads/ad_config.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/constants/wallet_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../communication/services/communication_firestore_service.dart';
import '../../consultations/providers/consultation_provider.dart';
import '../../consultations/services/payment_service.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';
import '../utils/guide_call_flow.dart';

/// Shared call wallet: balance, recharge (Razorpay), history. One balance
/// for calls with EVERY guide, billed per second at each guide's rate;
/// whatever isn't talked stays here.
///
/// Opened from the "Recharge" popup with the guide the user was trying to
/// call ([guideId]/[guideName]/[ratePaisePerMinute]) so, once there's
/// enough balance, `Call <guide> now` is one tap.
class WalletScreen extends ConsumerStatefulWidget {
  final String? guideId;
  final String? guideName;
  final int? ratePaisePerMinute;

  const WalletScreen({
    this.guideId,
    this.guideName,
    this.ratePaisePerMinute,
    super.key,
  });

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _selectedPaise = WalletConstants.rechargePresetsPaise[1];
  bool _processing = false;
  bool _calling = false;
  bool _watchingAd = false;

  // Rewarded-ad button follows the Super Admin toggle live.
  void _onAdSettings() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AdManager.instance.settings.addListener(_onAdSettings);
  }

  @override
  void dispose() {
    AdManager.instance.settings.removeListener(_onAdSettings);
    super.dispose();
  }

  /// Rewarded video -> wallet credit. The credit is made SERVER-side by
  /// AdMob's signed callback (functions/src/adRewards.js), so the balance
  /// above updates on its own a moment after the video finishes.
  Future<void> _watchAdForCredit(String uid) async {
    setState(() => _watchingAd = true);
    final outcome = await AdManager.instance.showRewarded(uid: uid);
    if (!mounted) return;
    setState(() => _watchingAd = false);
    switch (outcome) {
      case RewardedAdOutcome.rewarded:
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Thanks! ${formatRupees(AdConfig.rewardPaise)} will be '
              'added to your wallet in a moment.',
        );
      case RewardedAdOutcome.notRewarded:
        SnackBarHelper.showInfoSnackBar(
          context,
          message: 'Watch the video to the end to earn the credit.',
        );
      case RewardedAdOutcome.unavailable:
        SnackBarHelper.showInfoSnackBar(
          context,
          message: 'No video available right now. Please try again later.',
        );
    }
  }

  int get _rate =>
      widget.ratePaisePerMinute ?? WalletConstants.defaultRatePaisePerMinute;

  Future<void> _recharge() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final payments = ref.read(paymentServiceProvider);
    final wallet = ref.read(walletServiceProvider);
    setState(() => _processing = true);
    try {
      final order = await wallet.createRechargeOrder(_selectedPaise);
      final result = await payments.openCheckout(
        order: order,
        description: 'Wallet recharge ${formatRupees(_selectedPaise)}',
        contactEmail: user.email ?? '',
        contactPhone: user.phoneNumber ?? '',
      );
      await wallet.verifyRecharge(
        razorpayOrderId: result.orderId ?? order.razorpayOrderId,
        razorpayPaymentId: result.paymentId ?? '',
        razorpaySignature: result.signature ?? '',
      );
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: '${formatRupees(_selectedPaise)} added to your wallet.',
        );
      }
    } on PaymentException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    } catch (e) {
      debugPrint('[Wallet] recharge failed: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Recharge failed. If money was deducted it will be added '
              'to your wallet shortly.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _callGuide(String uid) async {
    final guideId = widget.guideId;
    if (guideId == null) return;
    setState(() => _calling = true);
    try {
      await startGuideCall(
        context: context,
        ref: ref,
        callerId: uid,
        guideId: guideId,
        guideName: widget.guideName ?? 'this guide',
        ratePaisePerMinute: _rate,
        callType: CommunicationConstants.callTypeVoice,
      );
    } on CommunicationException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    } catch (e) {
      debugPrint('[Wallet] call failed: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not start the call. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final balance = ref.watch(walletBalanceProvider(user.uid)).valueOrNull ?? 0;
    final txns =
        ref.watch(walletTransactionsProvider(user.uid)).valueOrNull ?? const [];
    final guideName = widget.guideName;
    final canCallGuide = widget.guideId != null &&
        talkSecondsFor(balance, _rate) >= WalletConstants.minCallSeconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Call Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance',
                    style: AppFonts.plusJakarta(
                        fontSize: 13, color: tokens.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  formatRupees(balance),
                  style: AppFonts.plusJakarta(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${talkSecondsFor(balance, _rate) ~/ 60} min at '
                  '${formatRupees(_rate)}/min'
                  '${guideName == null ? '' : ' with $guideName'} · '
                  'works with every guide',
                  style: AppFonts.plusJakarta(
                      fontSize: 12.5, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          if (canCallGuide) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _calling ? null : () => _callGuide(user.uid),
              icon: const Icon(Icons.call_rounded),
              label: Text('Call ${guideName ?? 'guide'} now'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
          if (AdManager.instance.rewardedAvailable) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _watchingAd ? null : () => _watchAdForCredit(user.uid),
              icon: _watchingAd
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ondemand_video_rounded),
              label: Text(
                'Watch a short video, get ${formatRupees(AdConfig.rewardPaise)} '
                '(up to ${AdConfig.rewardDailyCap}×/day)',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Add money',
              style: AppFonts.plusJakarta(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in WalletConstants.rechargePresetsPaise)
                ChoiceChip(
                  label: Text(
                    '${formatRupees(amount)} · ≈${talkSecondsFor(amount, _rate) ~/ 60} min',
                  ),
                  selected: _selectedPaise == amount,
                  onSelected: (_) => setState(() => _selectedPaise = amount),
                ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Recharge ${formatRupees(_selectedPaise)}',
            isLoading: _processing,
            onPressed: _recharge,
          ),
          const SizedBox(height: 8),
          Text(
            'Only the time you actually talk is charged, per second, at each '
            "guide's rate. Unused balance stays in your wallet.",
            style:
                AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
          ),
          if (txns.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('History',
                style: AppFonts.plusJakarta(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary)),
            const SizedBox(height: 8),
            for (final t in txns) _TransactionTile(t: t),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction t;

  const _TransactionTile({required this.t});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isAdReward = t.type == 'ad_reward';
    final isRecharge = t.type == 'recharge' || isAdReward;
    final mins = t.billedSeconds ~/ 60;
    final secs = t.billedSeconds % 60;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isAdReward
            ? Icons.ondemand_video_rounded
            : (isRecharge ? Icons.add_circle_outline : Icons.call_outlined),
        color: tokens.textSecondary,
      ),
      title: Text(
        isAdReward
            ? 'Video reward'
            : (isRecharge ? 'Recharge' : 'Call with ${t.guideAlias ?? 'guide'}'),
      ),
      subtitle: Text(
        isRecharge
            ? 'Balance ${formatRupees(t.balanceAfterPaise)}'
            : '${mins}m ${secs}s at ${formatRupees(t.ratePaisePerMinute)}/min · '
                'balance ${formatRupees(t.balanceAfterPaise)}',
      ),
      trailing: Text(
        '${isRecharge ? '+' : '−'}${formatRupees(t.amountPaise.abs())}',
        style: AppFonts.plusJakarta(
          fontWeight: FontWeight.w700,
          color: isRecharge ? Colors.green.shade700 : tokens.textPrimary,
        ),
      ),
    );
  }
}
