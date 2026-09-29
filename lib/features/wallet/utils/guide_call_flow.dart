import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/wallet_constants.dart';
import '../../communication/providers/communication_provider.dart';
import '../../communication/services/free_trial_call_service.dart';
import '../../communication/widgets/free_call_limit_dialog.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';

/// The one way to call a guide (guide profile, wallet "Call now"):
///
///   1. today's 2-minute free call with this guide, if still unused;
///   2. otherwise a paid call from the shared wallet at this guide's
///      per-minute rate (after a confirm showing rate + balance);
///   3. otherwise (balance can't cover a minute) the recharge popup.
///
/// Throws [CommunicationException]-style errors for everything else; the
/// caller shows them.
Future<void> startGuideCall({
  required BuildContext context,
  required WidgetRef ref,
  required String callerId,
  required String guideId,
  required String guideName,
  required int ratePaisePerMinute,
  required String callType,
}) async {
  final freeTrial = ref.read(freeTrialCallServiceProvider);

  // 1. Free call.
  final eligibility = await freeTrial.checkEligibility(
    callerId: callerId,
    guideId: guideId,
  );
  if (eligibility == FreeTrialEligibility.available) {
    try {
      final sessionId = await freeTrial.startFreeTrialCall(
        guideId: guideId,
        callType: callType,
      );
      if (context.mounted) context.push(RouteNames.activeCallPath(sessionId));
      return;
    } on FreeTrialUsedException {
      // Server says it's used after all -- fall through to a paid call.
    }
  }

  // 2. Paid call from the wallet.
  if (!context.mounted) return;
  final wallet = ref.read(walletServiceProvider);
  final balance = await wallet.getBalancePaise(callerId);
  if (!context.mounted) return;
  final talkSeconds = talkSecondsFor(balance, ratePaisePerMinute);
  if (talkSeconds < WalletConstants.minCallSeconds) {
    await showFreeCallLimitDialog(
      context,
      guideId: guideId,
      guideName: guideName,
      ratePaisePerMinute: ratePaisePerMinute,
      balancePaise: balance,
    );
    return;
  }

  final confirmed = await _confirmPaidCall(
    context,
    guideName: guideName,
    ratePaisePerMinute: ratePaisePerMinute,
    balancePaise: balance,
    freeCallUsed: eligibility == FreeTrialEligibility.usedToday,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final sessionId = await wallet.startPaidCall(
      guideId: guideId,
      callType: callType,
    );
    if (context.mounted) context.push(RouteNames.activeCallPath(sessionId));
  } on InsufficientBalanceException catch (e) {
    if (!context.mounted) return;
    await showFreeCallLimitDialog(
      context,
      guideId: guideId,
      guideName: guideName,
      ratePaisePerMinute: e.ratePaisePerMinute,
      balancePaise: e.balancePaise,
    );
  }
}

Future<bool?> _confirmPaidCall(
  BuildContext context, {
  required String guideName,
  required int ratePaisePerMinute,
  required int balancePaise,
  required bool freeCallUsed,
}) {
  final minutes = talkSecondsFor(balancePaise, ratePaisePerMinute) ~/ 60;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.account_balance_wallet_outlined),
      title: const Text('Paid call'),
      content: Text(
        '${freeCallUsed ? 'Your free 2 minutes with $guideName are used for today. ' : ''}'
        '$guideName charges ${formatRupees(ratePaisePerMinute)}/min.\n\n'
        'Wallet: ${formatRupees(balancePaise)} (≈ $minutes min with this guide). '
        'You only pay for the time you talk — the rest stays in your wallet '
        'for any guide.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Call now'),
        ),
      ],
    ),
  );
}
