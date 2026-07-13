import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/engagement/providers/engagement_provider.dart';

/// Runs non-critical warm-up work after the Home screen has painted.
class StartupBootstrap {
  StartupBootstrap._();

  static bool _started = false;

  static void runAfterHomeVisible(WidgetRef ref) {
    if (_started) return;
    _started = true;
    unawaited(_warmAssets());
    unawaited(_initEngagement(ref));
  }

  static Future<void> _warmAssets() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.poppins(fontWeight: FontWeight.w400),
        GoogleFonts.poppins(fontWeight: FontWeight.w600),
        GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ]);
    } catch (_) {
      // Font warm-up is best-effort; runtime fetch remains available.
    }
  }

  static Future<void> _initEngagement(WidgetRef ref) async {
    try {
      await ref.read(engagementMessagingInitProvider.future);
    } catch (_) {
      // FCM init is best-effort; in-app notifications still work.
    }
  }
}

/// Home sets this to true after the first frame so deferred providers can load.
final homeContentReadyProvider = StateProvider<bool>((ref) => false);
