import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/providers/college_provider.dart';
import 'package:college_reality_india/features/colleges/screens/college_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture search screenshot', (tester) async {
    AppFonts.useSystemFallback = true;
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpRouterApp(
      tester,
      initialLocation: '/college-search',
      overrides: [
        ...testAuthOverrides(),
        collegeDirectoryMetaProvider.overrideWith(
          (ref) async => const CollegeDirectoryMeta(totalColleges: 0),
        ),
        indianStatesProvider.overrideWith((ref) async => <String>['Maharashtra']),
        indianCoursesProvider.overrideWith((ref) async => <String>['B.Tech']),
        collegeSearchPageProvider.overrideWith(
          (ref, params) async => const CollegeSearchPage(colleges: []),
        ),
      ],
      routes: [
        GoRoute(
          path: '/college-search',
          builder: (_, _) => const RepaintBoundary(child: CollegeSearchScreen()),
        ),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

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
    File('screenshots/04_search.png')
        .writeAsBytesSync(byteData!.buffer.asUint8List());
  });
}