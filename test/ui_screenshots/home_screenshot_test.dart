import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:college_reality_india/config/theme/app_design_tokens.dart';
import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/config/theme/app_spacing.dart';
import 'package:college_reality_india/core/widgets/premium_components.dart';
import 'package:college_reality_india/features/home/widgets/explore_by_city_section.dart';
import 'package:college_reality_india/features/home/widgets/explore_category_section.dart';
import 'package:college_reality_india/features/home/widgets/home_college_discovery_card.dart';
import 'package:college_reality_india/features/home/widgets/home_compare_section.dart';
import 'package:college_reality_india/features/home/widgets/home_hero_panel.dart';
import 'package:college_reality_india/features/home/widgets/home_more_section.dart';
import 'package:college_reality_india/features/home/widgets/home_trust_section.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// Renders the *actual production widgets* that compose the new lean Home
/// screen — without going through `HomeScreen`'s `initState` (which fires
/// app-startup side effects that need a real Firebase app and aren't
/// testable in isolation). This keeps the screenshot a faithful, real
/// render of the redesigned home screen structure.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture home screen screenshot', (tester) async {
    AppFonts.useSystemFallback = true;
    await tester.binding.setSurfaceSize(const Size(390, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockUser = MockUser(
      uid: 'home-preview-user',
      email: 'aisha@example.com',
      displayName: 'Aisha Verma',
    );

    const boundaryKey = ValueKey('home-screenshot-boundary');

    await pumpScreen(
      tester,
      overrides: testAuthOverrides(
        authService: FakeAuthService(initialUser: mockUser),
        firebaseUser: mockUser,
      ),
      child: RepaintBoundary(
        key: boundaryKey,
        child: Builder(
          builder: (context) {
            final tokens = context.tokens;
            return Scaffold(
              backgroundColor: tokens.surfaceMuted,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeHeroPanel(
                        user: mockUser,
                        displayName: 'Aisha Verma',
                        subtitle: 'Real reviews & verified CR Scores, personalized for you',
                      ),
                      const SizedBox(height: AppSpacing.sectionLg),
                      SectionHeader(
                        title: 'Explore Colleges',
                        subtitle: 'Pick a stream to get started',
                        actionLabel: 'All categories',
                        onAction: () {},
                      ),
                      const ExploreCategoryGrid(),
                      const SizedBox(height: AppSpacing.sectionLg),
                      SectionHeader(
                        title: 'Recommended for You',
                        subtitle: 'Real colleges, real ratings — picked for you',
                        actionLabel: 'View all',
                        onAction: () {},
                      ),
                      const FeaturedCollegesSection(),
                      const SizedBox(height: AppSpacing.sectionLg),
                      const HomeTrustSection(),
                      const SizedBox(height: AppSpacing.sectionLg),
                      const HomeCompareSection(),
                      const SizedBox(height: AppSpacing.sectionLg),
                      const SectionHeader(
                        title: 'Explore by City',
                        subtitle: 'Find colleges near you',
                      ),
                      const ExploreCityCarousel(),
                      const SizedBox(height: AppSpacing.sectionLg),
                      const SectionHeader(
                        title: 'More to Explore',
                        subtitle: 'A few other ways to use College Reality',
                      ),
                      const HomeMoreSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
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
