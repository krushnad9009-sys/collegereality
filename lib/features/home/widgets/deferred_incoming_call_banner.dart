import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../communication/widgets/incoming_call_banner.dart';

/// Defers call-session Firestore listeners until Home has rendered.
class DeferredIncomingCallBanner extends ConsumerWidget {
  const DeferredIncomingCallBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(homeContentReadyProvider)) {
      return const SizedBox.shrink();
    }
    return const IncomingCallBanner();
  }
}
