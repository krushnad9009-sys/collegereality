import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/core/widgets/premium_components.dart';
import 'package:college_reality_india/features/profile/screens/profile_screen.dart';
import 'package:college_reality_india/features/reviews/screens/write_review_screen.dart';
import 'package:college_reality_india/features/reviews/widgets/star_rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

Future<void> _capture(WidgetTester tester, String path) async {
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
  File(path).writeAsBytesSync(byteData!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture details reviews profile screenshots', (tester) async {
    AppFonts.useSystemFallback = true;
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: RepaintBoundary(
        child: Scaffold(
          backgroundColor: AppTheme.surfaceMuted,
          appBar: AppBar(
            title: const Text('College Details'),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Sample Institute of Technology'),
                    SizedBox(height: 8),
                    StarRatingWidget(rating: 4.5, starSize: 22, readOnly: true),
                    SizedBox(height: 12),
                    Text('Premium college detail chrome'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'screenshots/05_college_details.png');

    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const RepaintBoundary(
        child: WriteReviewScreen(collegeId: 'c1', collegeName: 'Test College'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'screenshots/06_reviews.png');

    await pumpScreen(
      tester,
      overrides: testAuthOverrides(),
      child: const RepaintBoundary(child: ProfileScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'screenshots/07_profile.png');
  });
}