import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture login screenshot', (tester) async {
    AppFonts.useSystemFallback = true;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(
      tester,
      child: const RepaintBoundary(child: LoginScreen()),
      overrides: testAuthOverrides(),
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
    Directory('screenshots').createSync(recursive: true);
    File('screenshots/02_login.png')
        .writeAsBytesSync(byteData!.buffer.asUint8List());
  });
}