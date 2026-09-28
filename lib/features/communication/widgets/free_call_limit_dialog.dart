import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';

/// Shown instead of connecting when this user already used today's
/// 2-minute free call with [guideId]. "Pay Now" opens that guide's paid
/// consultation checkout (Razorpay), which is the paid way to keep talking.
Future<void> showFreeCallLimitDialog(
  BuildContext context, {
  required String guideId,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.timer_off_outlined),
      title: const Text('Free call used'),
      content: const Text(
        'You have used your 2-minute free call for this Guide today. '
        'Please recharge/pay to continue calling.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.push(RouteNames.consultationCheckoutPath(guideId));
          },
          child: const Text('Pay Now'),
        ),
      ],
    ),
  );
}
