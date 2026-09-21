import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/config/theme/app_theme.dart';
import 'package:college_reality_india/core/widgets/app_shell.dart';
import 'package:college_reality_india/features/community/providers/presence_heartbeat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _FakeHeartbeat extends Mock implements PresenceHeartbeatController {}

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  String initial = RouteNames.home,
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          for (final path in [
            RouteNames.home,
            RouteNames.collegeSearch,
            RouteNames.assistant,
            RouteNames.communityPrivateChats,
            RouteNames.profile,
          ])
            GoRoute(
              path: path,
              builder: (_, _) => Center(child: Text('PAGE $path')),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presenceHeartbeatControllerProvider.overrideWithValue(_FakeHeartbeat()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('has the five destinations: Home, Search, Assistant, Chats, '
      'Profile', (tester) async {
    await _pumpShell(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.destinations.map((d) => (d as NavigationDestination).label).toList(),
      ['Home', 'Search', 'Assistant', 'Chats', 'Profile'],
    );
    expect(bar.selectedIndex, 0);
  });

  testWidgets('is a minimal docked white bar: full width, flush with the '
      'bottom, one hairline on top, no blur', (tester) async {
    await _pumpShell(tester, size: const Size(390, 800));

    final barRect = tester.getRect(find.byType(NavigationBar));
    expect(barRect.left, 0);
    expect(barRect.right, 390, reason: 'full width, not a floating pill');
    expect(barRect.bottom, 800, reason: 'docked to the bottom edge');

    final surface = tester
        .widgetList<DecoratedBox>(
          find.ancestor(
            of: find.byType(NavigationBar),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .first;
    expect(surface.color, Colors.white);
    expect(surface.borderRadius, isNull);
    expect(surface.boxShadow, isNull);
    expect(surface.border, isNotNull);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.backgroundColor, Colors.white);
    // No frosted-glass blur anywhere in the shell.
    expect(
      find.descendant(
        of: find.byType(AppShell),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
  });

  testWidgets('the active Home icon uses the hero blue', (tester) async {
    await _pumpShell(tester);
    final home = tester.widgetList<Icon>(find.byIcon(Icons.home_rounded));
    expect(home.map((i) => i.color), contains(const Color(0xFF093F72)));
  });

  testWidgets('tapping a destination navigates there', (tester) async {
    final router = await _pumpShell(tester);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.collegeSearch,
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('other tabs keep the brand teal accent', (tester) async {
    await _pumpShell(tester, initial: RouteNames.profile);
    final profile = tester.widgetList<Icon>(find.byIcon(Icons.person_rounded));
    expect(profile.map((i) => i.color), contains(AppTheme.primaryColor));
  });
}
