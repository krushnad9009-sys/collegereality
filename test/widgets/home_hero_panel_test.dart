import 'dart:math' as math;

import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/config/theme/app_design_tokens.dart';
import 'package:college_reality_india/config/theme/app_spacing.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/config/theme/premium_home_theme.dart';
import 'package:college_reality_india/features/home/widgets/home_header_widget.dart';
import 'package:college_reality_india/features/home/widgets/home_hero_panel.dart';
import 'package:college_reality_india/features/home/widgets/premium_home_search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

final _signedIn = MockUser(
  uid: 'u1',
  email: 'student@example.com',
  displayName: 'dk007',
);

const _subtitle = 'Real reviews & verified CR Scores, personalized for you';

Future<void> _pumpHero(
  WidgetTester tester, {
  required double width,
  required User? user,
  double height = 900,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await pumpScreen(
    tester,
    overrides: testAuthOverrides(
      firebaseUser: user,
      userDetail: user == null
          ? null
          : testUserModel(uid: 'u1', email: 'student@example.com'),
    ),
    child: Scaffold(
      body: PremiumHomeTheme(
        child: Column(
          children: [
            HomeHeroPanel(
              user: user,
              displayName: 'dk007',
              subtitle: _subtitle,
              onMenuPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tokens = AppTheme.premiumLightTheme.extension<AppDesignTokens>()!;

  group('hero card', () {
    testWidgets('is a solid #093F72 block with rounded BOTTOM corners only', (
      tester,
    ) async {
      await _pumpHero(tester, width: 390, user: _signedIn);

      final hero = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(HomeHeroPanel),
              matching: find.byType(Container),
            ),
          )
          .first;
      final deco = hero.decoration! as BoxDecoration;
      expect(deco.color, const Color(0xFF093F72));
      expect(deco.gradient, isNull, reason: 'solid, not a gradient');
      expect(
        deco.borderRadius,
        const BorderRadius.vertical(bottom: Radius.circular(28)),
      );
      // Full-width, flush with the screen edges.
      expect(tester.getSize(find.byType(HomeHeroPanel)).width, 390);
      expect(tester.getTopLeft(find.byType(HomeHeroPanel)).dx, 0);
    });

    test('white text is ~11:1 on the hero blue', () {
      double lum(Color c) {
        double ch(double v) => v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
        return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
      }

      final ratio = 1.05 / (lum(tokens.heroColor) + 0.05);
      expect(ratio, greaterThan(9));
    });

    testWidgets('greeting + subtitle are white, on two lines', (tester) async {
      await _pumpHero(tester, width: 390, user: _signedIn);

      final greeting = tester.widget<Text>(find.textContaining(', dk007'));
      expect(greeting.style?.color, Colors.white);
      expect(greeting.data, startsWith('Good '));

      final subtitle = tester.widget<Text>(find.text(_subtitle));
      expect(subtitle.style?.color?.a, greaterThan(0.8));
      expect(
        tester.getTopLeft(find.text(_subtitle)).dy,
        greaterThan(tester.getBottomLeft(find.textContaining(', dk007')).dy),
      );
    });

    testWidgets('holds a rounded, full-width white search bar reading '
        '"Find the right college"', (tester) async {
      await _pumpHero(tester, width: 390, user: _signedIn);

      expect(find.text('Find the right college'), findsOneWidget);
      final bar = find.byType(PremiumHomeSearchBar);
      final box =
          tester
                  .widgetList<Container>(
                    find.descendant(of: bar, matching: find.byType(Container)),
                  )
                  .first
                  .decoration!
              as BoxDecoration;
      expect(box.color, Colors.white);
      expect(box.borderRadius, BorderRadius.circular(999));

      // Spans the content width: the hero minus its 20px gutters.
      expect(tester.getSize(bar).width, moreOrLessEquals(390 - 2 * 20));
      // ...and sits inside the blue card, below the greeting.
      final hero = tester.getRect(find.byType(HomeHeroPanel));
      expect(hero.contains(tester.getCenter(bar)), isTrue);
      expect(
        tester.getTopLeft(bar).dy,
        greaterThan(tester.getBottomLeft(find.text(_subtitle)).dy),
      );
    });

    testWidgets('tapping the search bar opens search', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: HomeHeroPanel(
                user: null,
                displayName: 'x',
                subtitle: _subtitle,
                onMenuPressed: () {},
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.collegeSearch,
            builder: (_, state) =>
                Text('SEARCH filters=${state.uri.queryParameters['filters']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Find the right college'));
      await tester.pumpAndSettle();
      expect(find.text('SEARCH filters=null'), findsOneWidget);
    });
  });

  group('top bar', () {
    // The hero's content spans [left, right] below: it is centred, at most
    // maxContentWidth wide, and inset by the gutter.
    for (final width in [375.0, 900.0, 1600.0]) {
      testWidgets(
        'lines up with the page content edges at ${width.toInt()}px',
        (tester) async {
          await _pumpHero(tester, width: width, user: _signedIn);

          final gutter = width < 600 ? AppSpacing.pageH : AppSpacing.pageHWide;
          final boxWidth = width < AppSpacing.maxContentWidth
              ? width
              : AppSpacing.maxContentWidth;
          final contentLeft = (width - boxWidth) / 2 + gutter;
          final contentRight = (width + boxWidth) / 2 - gutter;

          expect(
            tester.getTopLeft(find.byTooltip('Open navigation menu')).dx,
            moreOrLessEquals(contentLeft),
          );
          expect(
            tester.getTopRight(find.byType(HomeHeaderActions)).dx,
            moreOrLessEquals(contentRight),
          );
        },
      );
    }

    testWidgets('reads: menu, title, search, filter, notification, avatar', (
      tester,
    ) async {
      await _pumpHero(tester, width: 900, user: _signedIn);

      final xs = <double>[
        tester.getCenter(find.byTooltip('Open navigation menu')).dx,
        tester.getCenter(find.text('College Reality')).dx,
        tester.getCenter(find.byTooltip('Search colleges')).dx,
        tester.getCenter(find.byTooltip('Filters')).dx,
        tester.getCenter(find.byIcon(Icons.notifications_outlined)).dx,
        // The avatar: the only text inside the actions widget (its initial).
        tester
            .getCenter(
              find.descendant(
                of: find.byType(HomeHeaderActions),
                matching: find.byType(Text),
              ),
            )
            .dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()), reason: 'left-to-right');
      expect(xs.toSet(), hasLength(6));

      // All on one row.
      final ys = <double>[
        tester.getCenter(find.byTooltip('Open navigation menu')).dy,
        tester.getCenter(find.text('College Reality')).dy,
        tester.getCenter(find.byTooltip('Filters')).dy,
        tester.getCenter(find.byIcon(Icons.notifications_outlined)).dy,
      ];
      for (final y in ys) {
        expect(y, moreOrLessEquals(ys.first, epsilon: 1));
      }
    });

    testWidgets('icons are white on the blue', (tester) async {
      await _pumpHero(tester, width: 390, user: _signedIn);
      for (final icon in [
        Icons.menu_rounded,
        Icons.search_rounded, // also the search bar's magnifier (grey)
        Icons.tune_rounded,
      ]) {
        final whites = tester
            .widgetList<Icon>(find.byIcon(icon))
            .where((i) => i.color == Colors.white);
        expect(whites, isNotEmpty, reason: '$icon');
      }
      expect(
        tester.widget<Text>(find.text('College Reality')).style?.color,
        Colors.white,
      );
    });

    testWidgets('Filter opens search with the filter panel requested', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: HomeHeroPanel(
                user: null,
                displayName: 'x',
                subtitle: _subtitle,
                onMenuPressed: () {},
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.collegeSearch,
            builder: (_, state) =>
                Text('SEARCH filters=${state.uri.queryParameters['filters']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('SEARCH filters=1'), findsOneWidget);
    });

    testWidgets('the menu button fires its callback', (tester) async {
      var opened = 0;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        child: Scaffold(
          body: HomeHeroPanel(
            user: null,
            displayName: 'x',
            subtitle: _subtitle,
            onMenuPressed: () => opened++,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open navigation menu'));
      expect(opened, 1);
    });

    testWidgets('signed-out visitors get a Sign in pill instead of the bell '
        'and avatar', (tester) async {
      await _pumpHero(tester, width: 900, user: null);

      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      expect(find.text('College Reality'), findsOneWidget);
      expect(find.byTooltip('Search colleges'), findsOneWidget);
      expect(find.byTooltip('Filters'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byType(HomeHeaderActions), findsNothing);
      expect(find.text('Find your dream college'), findsOneWidget);
    });

    testWidgets('fits a very narrow phone without overflowing', (tester) async {
      await _pumpHero(tester, width: 320, user: _signedIn);
      expect(tester.takeException(), isNull);
      expect(find.text('College Reality'), findsOneWidget);
    });
  });
}
