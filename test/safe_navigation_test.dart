import 'package:college_reality_india/core/navigation/safe_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(PushGuard.reset);

  group('PushGuard', () {
    final t0 = DateTime(2026, 9, 30, 12);

    test('skips pushing the page that is already on top', () {
      expect(
        PushGuard.shouldSkip(target: '/wallet', current: '/wallet', now: t0),
        isTrue,
      );
      expect(
        PushGuard.shouldSkip(target: '/wallet/', current: '/wallet', now: t0),
        isTrue,
      );
    });

    test('a fast double tap pushes once', () {
      expect(
        PushGuard.shouldSkip(target: '/guides/a', current: '/home', now: t0),
        isFalse,
      );
      expect(
        PushGuard.shouldSkip(
          target: '/guides/a',
          current: '/home',
          now: t0.add(const Duration(milliseconds: 200)),
        ),
        isTrue,
      );
    });

    test('the same page can be opened again after the debounce', () {
      PushGuard.shouldSkip(target: '/guides/a', current: '/home', now: t0);
      expect(
        PushGuard.shouldSkip(
          target: '/guides/a',
          current: '/home',
          now: t0.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('different pages and different query strings are not duplicates', () {
      expect(
        PushGuard.shouldSkip(target: '/guides/a', current: '/guides/b', now: t0),
        isFalse,
      );
      expect(
        PushGuard.shouldSkip(
            target: '/wallet?guideId=x', current: '/wallet', now: t0),
        isFalse,
      );
    });
  });

  Future<GoRouter> pumpRouter(WidgetTester tester, String initial) async {
    Widget page(String name) => Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Text('PAGE $name'),
                TextButton(
                  onPressed: () => context.popOrGo(),
                  child: const Text('back'),
                ),
                TextButton(
                  onPressed: () => context.pushOnce('/detail'),
                  child: const Text('open detail'),
                ),
              ],
            ),
          ),
        );
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/home', builder: (_, _) => page('home')),
        GoRoute(path: '/detail', builder: (_, _) => page('detail')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('back on a screen opened with go() (nothing to pop) goes Home '
      'instead of doing nothing', (tester) async {
    await pumpRouter(tester, '/detail');
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back on a pushed screen pops normally', (tester) async {
    await pumpRouter(tester, '/home');
    await tester.tap(find.text('open detail'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE detail'), findsOneWidget);

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE home'), findsOneWidget);
  });

  testWidgets('double-tapping a button opens ONE copy; one back returns',
      (tester) async {
    await pumpRouter(tester, '/home');
    await tester.tap(find.text('open detail'));
    await tester.tap(find.text('open detail'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('back').last);
    await tester.pumpAndSettle();
    expect(find.text('PAGE home'), findsOneWidget);
    expect(find.text('PAGE detail'), findsNothing);
  });
}
