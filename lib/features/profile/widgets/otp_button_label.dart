import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';

/// Button child for OTP "Send / Resend / Verify" actions that cross-fades
/// between its text label and a compact spinner as [loading] toggles.
class OtpButtonLabel extends StatelessWidget {
  final bool loading;
  final String label;
  final Color? spinnerColor;

  const OtpButtonLabel({
    required this.loading,
    required this.label,
    this.spinnerColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: 200.ms,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: loading
          ? SizedBox(
              key: const ValueKey('otp-btn-spinner'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: spinnerColor,
              ),
            )
          : Text(label, key: ValueKey('otp-btn-$label')),
    );
  }
}
