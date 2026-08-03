import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/features/home/widgets/home_hero_banner.dart';
import 'package:college_reality_india/features/home/widgets/premium_home_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture home hero screenshot', (tester) async {
    AppFonts.useSystemFallback = true;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: RepaintBoundary(
        child: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                HomeHeroBanner(
                  greeting: 'Find your dream college',
                  subtitle: 'Honest reviews from real students',
                ),
                SizedBox(height: 8),
                PremiumHomeSearchBar(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).last,
    );
    ByteData? byteData;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    });
    expect(byteData, isNotNull);
    Directory('screenshots').createSync(recursive: true);
    File('screenshots/03_home.png')
        .writeAsBytesSync(byteData!.buffer.asUint8List());
  });
}