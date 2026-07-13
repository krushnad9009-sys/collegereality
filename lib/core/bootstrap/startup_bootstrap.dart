import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs non-critical warm-up work after the Home screen has painted.
class StartupBootstrap {
  StartupBootstrap._();

  static bool _started = false;

  static void runAfterHomeVisible(WidgetRef ref) {
    if (_started) return;
    _started = true;
    unawaited(_warmAssets());
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
}

/// Home sets this to true after the first frame so deferred providers can load.
final homeContentReadyProvider = StateProvider<bool>((ref) => false);
