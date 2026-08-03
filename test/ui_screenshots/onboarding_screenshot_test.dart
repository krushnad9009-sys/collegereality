import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/features/auth/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture onboarding screenshot', (tester) async {
    AppFonts.useSystemFallback = true;
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RepaintBoundary(child: OnboardingScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).last,
    );

    late ui.Image image;
    ByteData? byteData;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: 2);
      byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    });
    expect(byteData, isNotNull);

    final dir = Directory('screenshots');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('screenshots/01_onboarding.png').writeAsBytesSync(
      byteData!.buffer.asUint8List(),
    );
  });
}