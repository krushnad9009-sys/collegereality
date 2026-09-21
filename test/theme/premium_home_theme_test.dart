import 'dart:math' as math;

import 'package:college_reality_india/config/theme/app_design_tokens.dart';
import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/config/theme/premium_home_theme.dart';
import 'package:college_reality_india/core/widgets/premium_components.dart';
import 'package:college_reality_india/features/home/widgets/home_core_features_grid.dart';
import 'package:college_reality_india/features/home/widgets/explore_by_city_section.dart';
import 'package:college_reality_india/features/home/widgets/explore_category_section.dart';
import 'package:college_reality_india/config/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(() => AppFonts.useSystemFallback = true);

  group('premium palette', () {
    final theme = AppTheme.premiumLightTheme;
    final tokens = theme.extension<AppDesignTokens>()!;

    test('uses the specified slate / off-white / white / border / indigo', () {
      expect(theme.colorScheme.primary, const Color(0xFF0F172A));
      expect(theme.colorScheme.secondary, const Color(0xFF6366F1));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(tokens.surfaceMuted, const Color(0xFFF8FAFC));
      expect(tokens.surfaceElevated, const Color(0xFFFFFFFF));
      expect(tokens.borderSubtle, const Color(0xFFE2E8F0));
      expect(tokens.accentCool, const Color(0xFF6366F1));
    });

    test('cards: 16px radius and the ultra-soft diffused shadow', () {
      expect(tokens.cardRadius, 16);
      final shadow = tokens.cardShadow!.single;
      expect(shadow.color.a, closeTo(0.04, 0.005));
      expect(shadow.blurRadius, 12);
      expect(shadow.offset, const Offset(0, 4));
      expect(tokens.flatSurfaces, isTrue);
    });

    test('typography: SemiBold headings over Regular body', () {
      expect(tokens.headingWeight, FontWeight.w600);
      expect(tokens.bodyWeight, FontWeight.w400);
      expect(theme.textTheme.headlineMedium!.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyMedium!.fontWeight, FontWeight.w400);
    });

    test('primary actions use the slate, not the legacy teal', () {
      final filled = theme.filledButtonTheme.style!.backgroundColor!.resolve(
        <WidgetState>{},
      );
      expect(filled, const Color(0xFF0F172A));
    });

    test(
      'text stays accessible (WCAG AA, 4.5:1) on the surfaces it sits on',
      () {
        expect(
          _contrast(tokens.textPrimary, tokens.surfaceMuted),
          greaterThan(4.5),
        );
        expect(
          _contrast(tokens.textPrimary, tokens.surfaceElevated),
          greaterThan(4.5),
        );
        expect(
          _contrast(tokens.textSecondary, tokens.surfaceElevated),
          greaterThan(4.5),
        );
        expect(
          _contrast(tokens.textTertiary, tokens.surfaceElevated),
          greaterThan(4.5),
        );
        expect(
          _contrast(Colors.white, theme.colorScheme.primary),
          greaterThan(4.5),
        );
      },
    );
  });

  group('the rest of the app is untouched', () {
    test('the default light theme keeps the brand teal and legacy tokens', () {
      final theme = AppTheme.lightTheme;
      final tokens = theme.extension<AppDesignTokens>()!;
      expect(theme.colorScheme.primary, AppTheme.primaryColor);
      expect(tokens.cardRadius, 22);
      expect(tokens.headingWeight, FontWeight.w800);
      expect(tokens.bodyWeight, FontWeight.w500);
      expect(tokens.cardShadow, isNull);
      expect(tokens.flatSurfaces, isFalse);
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve(
          <WidgetState>{},
        ),
        AppTheme.primaryColor,
      );
      expect(theme.textTheme.bodyMedium!.fontWeight, FontWeight.w500);
    });

    test('the dark theme keeps its lighter teal action colour', () {
      final theme = AppTheme.darkTheme;
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve(
          <WidgetState>{},
        ),
        AppTheme.primaryLight,
      );
    });

    test('PremiumHomeTheme upgrades light but leaves dark alone', () {
      expect(
        PremiumHomeTheme.resolve(AppTheme.lightTheme),
        same(AppTheme.premiumLightTheme),
      );
      final dark = AppTheme.darkTheme;
      expect(PremiumHomeTheme.resolve(dark), same(dark));
    });

    testWidgets('a legacy SectionHeader is still heavy; inside the premium '
        'theme it turns SemiBold', (tester) async {
      const header = SectionHeader(title: 'Explore');
      FontWeight? weightOf() =>
          tester.widget<Text>(find.text('Explore')).style?.fontWeight;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: header),
        ),
      );
      expect(weightOf(), FontWeight.w800);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: PremiumHomeTheme(child: header)),
        ),
      );
      expect(weightOf(), FontWeight.w600);
    });

    testWidgets('PremiumHomeTheme applies its palette to descendants only in '
        'light mode', (tester) async {
      Color? primary;
      Widget probe() => Builder(
        builder: (context) {
          primary = Theme.of(context).colorScheme.primary;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: PremiumHomeTheme(child: probe()),
        ),
      );
      await tester.pumpAndSettle();
      expect(primary, const Color(0xFF0F172A));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: PremiumHomeTheme(child: probe()),
        ),
      );
      // MaterialApp animates theme changes; let it finish before reading.
      await tester.pumpAndSettle();
      expect(primary, AppTheme.primaryLight);
    });
  });

  group('category chips, city badges, action cards', () {
    final tokens = AppTheme.premiumLightTheme.extension<AppDesignTokens>()!;

    Widget inPremium(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(child: PremiumHomeTheme(child: child)),
      ),
    );

    test('the hero is the specified solid royal blue', () {
      expect(tokens.heroColor, const Color(0xFF093F72));
      expect(_contrast(Colors.white, tokens.heroColor), greaterThan(9));
    });

    // ---------------------------------------------------------- chips
    group('category chips', () {
      const labels = [
        'Engineering',
        'Medical',
        'MBA',
        'Law',
        'Pharmacy',
        'Arts',
        'Commerce',
      ];
      // Hue ranges (degrees) the brief asks for; grey has no hue.
      final hues = <String, (double, double)?>{
        'Engineering': (200, 235), // blue
        'Medical': (315, 345), // pink
        'MBA': (15, 40), // light orange
        'Law': (160, 185), // teal
        'Pharmacy': (250, 275), // purple
        'Arts': (30, 65), // yellow (icon is a darkened amber for contrast)
        'Commerce': null, // grey
      };

      ActionChip chipFor(WidgetTester tester, String label) =>
          tester.widget<ActionChip>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(ActionChip),
            ),
          );

      testWidgets('are ONE scrolling row of seven pills, in order', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(inPremium(const ExploreCategoryChips()));
        await tester.pumpAndSettle();

        final list = tester.widget<ListView>(find.byType(ListView));
        expect(list.scrollDirection, Axis.horizontal);
        // Reach every chip by scrolling the single row; collect their order.
        final seenAt = <String, double>{};
        for (final label in labels) {
          await tester.scrollUntilVisible(
            find.text(label),
            100,
            scrollable: find.byType(Scrollable).last,
          );
          seenAt[label] = tester.getCenter(find.text(label)).dy;
        }
        // Same vertical position for all: one row, not a grid.
        final ys = seenAt.values.toList();
        for (final y in ys) {
          expect(y, moreOrLessEquals(ys.first, epsilon: 0.5));
        }
        expect(find.byType(ActionChip), findsWidgets);
        expect(find.byType(GridView), findsNothing);
      });

      testWidgets('are compact pills, not big tiles', (tester) async {
        await tester.pumpWidget(inPremium(const ExploreCategoryChips()));
        await tester.pumpAndSettle();
        final size = tester.getSize(find.byType(ActionChip).first);
        expect(size.height, lessThanOrEqualTo(48));
        expect(chipFor(tester, 'Law').shape, isA<StadiumBorder>());
      });

      for (final label in labels) {
        testWidgets('$label: soft tint, colourful icon, dark readable text', (
          tester,
        ) async {
          await tester.pumpWidget(inPremium(const ExploreCategoryChips()));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(label),
            100,
            scrollable: find.byType(Scrollable).last,
          );

          final chip = chipFor(tester, label);
          final tint = chip.backgroundColor!;
          final icon = chip.avatar! as Icon;
          final accent = icon.color!;

          // Soft: a light pastel, never a saturated fill.
          expect(HSLColor.fromColor(tint).lightness, greaterThan(0.85));
          // Colourful: the icon is a saturated hue (grey for Commerce).
          final hsl = HSLColor.fromColor(accent);
          final range = hues[label];
          if (range == null) {
            expect(hsl.saturation, lessThan(0.25), reason: 'grey accent');
            expect(HSLColor.fromColor(tint).saturation, lessThan(0.3));
          } else {
            expect(hsl.saturation, greaterThan(0.5));
            expect(
              hsl.hue,
              inInclusiveRange(range.$1, range.$2),
              reason: '$label icon hue',
            );
            expect(
              HSLColor.fromColor(tint).hue,
              inInclusiveRange(range.$1 - 10, range.$2 + 10),
              reason: '$label tint hue',
            );
          }
          // Readable: dark ink on the tint; icon clearly visible on it.
          final ink = chip.labelStyle!.color!;
          expect(ink, ExploreCategoryChips.ink);
          expect(_contrast(ink, tint), greaterThan(12));
          expect(_contrast(accent, tint), greaterThan(3));
        });
      }

      testWidgets('tapping a chip searches that stream', (tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  const Scaffold(body: Center(child: ExploreCategoryChips())),
            ),
            GoRoute(
              path: RouteNames.collegeSearch,
              builder: (_, state) =>
                  Text('SEARCH ${state.uri.queryParameters['category']}'),
            ),
          ],
        );
        addTearDown(router.dispose);
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('MBA'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        // Fully on-screen (the chip may only be partly visible after the
        // scroll), so the tap lands on its centre.
        await tester.ensureVisible(find.text('MBA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('MBA'));
        await tester.pumpAndSettle();
        expect(find.text('SEARCH MBA'), findsOneWidget);
      });
    });

    // ---------------------------------------------------------- cities
    testWidgets('cities are a horizontally scrolling row of circular badges', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(inPremium(const ExploreCityCarousel()));
      await tester.pumpAndSettle();

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.scrollDirection, Axis.horizontal);

      for (final city in [
        'Mumbai',
        'Pune',
        'Delhi',
        'Bengaluru',
        'Chennai',
        'Hyderabad',
      ]) {
        await tester.scrollUntilVisible(
          find.text(city),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(city), findsOneWidget);
      }

      final circle = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.shape == BoxShape.circle);
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.location_city_rounded).first,
      );
      expect(icon.color, tokens.heroColor);
      expect(icon.color!.a, 1);
      expect(_contrast(icon.color!, circle.color!), greaterThan(4.5));
      expect(circle.border, isNotNull);
    });

    // ---------------------------------------------------------- actions
    testWidgets('all three action cards are saturated gradients with white '
        'text that clears AA at both ends', (tester) async {
      await tester.pumpWidget(inPremium(const HomeCoreFeaturesGrid()));
      await tester.pumpAndSettle();

      final gradients = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.gradient)
          .whereType<LinearGradient>()
          .toList();
      // Icon tiles are plain fills, so the only gradients are the 3 cards.
      expect(gradients, hasLength(3));

      final firstStops = <Color>{};
      for (final g in gradients) {
        firstStops.add(g.colors.first);
        for (final end in g.colors) {
          expect(
            _contrast(Colors.white, end),
            greaterThan(4.5),
            reason: 'white on $end',
          );
          final hsl = HSLColor.fromColor(end);
          expect(hsl.saturation, greaterThan(0.5), reason: '$end saturation');
        }
      }
      expect(firstStops, hasLength(3));

      Color? titleColor(String t) =>
          tester.widget<Text>(find.textContaining(t)).style?.color;
      expect(titleColor('Verified Student'), Colors.white);
      expect(titleColor('Assistant'), Colors.white);
      expect(titleColor('Colleges'), Colors.white);
    });
  });
}
