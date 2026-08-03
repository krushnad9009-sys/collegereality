import 'dart:async';

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppFonts.useSystemFallback = true;
  await testMain();
}