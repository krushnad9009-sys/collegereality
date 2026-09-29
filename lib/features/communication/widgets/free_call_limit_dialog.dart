import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../core/constants/wallet_constants.dart';

/// Shown instead of connecting when the caller can't talk to [guideId] for
/// free (today's 2-minute free call is used) AND their wallet can't pay
/// for at least a minute at this guide's rate. "Recharge" opens the shared
/// wallet, which then offers to call this guide straight away.
Future<void> showFreeCallLimitDialog(
  BuildContext context, {
  required String guideId,
  String? guideName,
  int? ratePaisePerMinute,
  int? balancePaise,
  bool freeCallUsed = true,
}) {
  final rate = ratePaisePerMinute ?? WalletConstants.defaultRatePaisePerMinute;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.timer_off_outlined),
      title: Text(freeCallUsed ? 'Free call used' : 'Recharge to call'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            freeCallUsed
                ? 'You have used your 2-minute free call for this Guide '
                    'today. Please recharge/pay to continue calling.'
                : 'Your wallet balance is too low for a call with this guide.',
          ),
          const SizedBox(height: 12),
          Text(
            '${formatRupees(rate)}/min'
            '${balancePaise == null ? '' : ' · Wallet: ${formatRupees(balancePaise)}'}\n'
            'Your balance works with every guide, and you only pay for the '
            'time you talk.',
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.push(RouteNames.walletPath(
              guideId: guideId,
              guideName: guideName,
              ratePaisePerMinute: rate,
            ));
          },
          child: const Text('Recharge'),
        ),
      ],
    ),
  );
}
