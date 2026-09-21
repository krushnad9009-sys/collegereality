import 'dart:async';

import 'package:college_reality_india/config/router/route_names.dart';
import 'package:college_reality_india/config/theme/app_fonts.dart';
import 'package:college_reality_india/core/constants/community_constants.dart';
import 'package:college_reality_india/core/constants/profile_constants.dart';
import 'package:college_reality_india/core/widgets/async_state_widgets.dart';
import 'package:college_reality_india/core/widgets/premium_components.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:college_reality_india/features/communication/models/public_guide_profile.dart';
import 'package:college_reality_india/features/communication/providers/communication_provider.dart';
import 'package:college_reality_india/features/communication/screens/guides_directory_screen.dart';
import 'package:college_reality_india/features/community/models/chat_conversation_model.dart';
import 'package:college_reality_india/features/community/models/user_presence_model.dart';
import 'package:college_reality_india/features/community/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

PublicGuideProfile guide(
  String uid,
  String name, {
  String? college,
  String? course,
  bool online = false,
  double rating = 0,
  int ratings = 0,
}) {
  return PublicGuideProfile(
    uid: uid,
    displayName: name,
    anonymousAlias: 'Guide $uid',
    languagesKnown: const ['English', 'Hindi'],
    collegeName: college,
    course: course,
    stats: GuideStatsModel(overallRating: rating, totalRatings: ratings),
    settings: const GuideCommunicationSettings(isGuideAvailable: true),
    presence: online
        ? UserPresenceModel(
            availabilityStatus: ProfileConstants.availabilityAvailable,
            lastSeenAt: DateTime.now(),
          )
        : const UserPresenceModel(),
  );
}

ChatConversationModel chat(String id, String peer, DateTime at, String text) {
  return ChatConversationModel(
    id: id,
    type: CommunityConstants.typePrivate,
    participantIds: ['me', 'peer-$id'],
    participantNames: {'me': 'Me', 'peer-$id': peer},
    lastMessageText: text,
    lastMessageAt: at,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => AppFonts.useSystemFallback = true);

  late List<String?> languagesAsked;

  final iit = guide(
    'iit',
    'Aisha Khan',
    college: 'IIT Bombay',
    course: 'B.Tech Computer Science',
    rating: 4.2,
    ratings: 8,
  );
  final aiims = guide(
    'aiims',
    'Rahul Verma',
    college: 'AIIMS Delhi',
    course: 'MBBS',
    online: true,
    rating: 3.5,
    ratings: 3,
  );

  /// Pumps `/guides` as the router would, with stub destinations that just
  /// print where they were sent.
  Future<void> pumpGuides(
    WidgetTester tester, {
    List<PublicGuideProfile> guides = const [],
    List<ChatConversationModel> chats = const [],
    Future<List<PublicGuideProfile>> Function()? load,
    // The loading skeleton animates forever, so it can never "settle".
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    languagesAsked = [];

    Widget at(GoRouterState state) => Scaffold(body: Text('AT ${state.uri}'));

    await pumpRouterApp(
      tester,
      initialLocation: RouteNames.guidesDirectory,
      overrides: [
        ...testAuthOverrides(
          userDetail: testUserModel(uid: 'me', email: 'me@example.com'),
        ),
        guidesDirectoryProvider.overrideWith((ref, language) {
          languagesAsked.add(language);
          return load != null ? load() : Future.value(guides);
        }),
        privateConversationsProvider.overrideWith((ref) => Stream.value(chats)),
      ],
      routes: [
        GoRoute(
          path: RouteNames.guidesDirectory,
          builder: (_, _) => const GuidesDirectoryScreen(),
        ),
        GoRoute(path: '/guides/:uid', builder: (_, s) => at(s)),
        for (final path in [
          RouteNames.communityPrivateChats,
          RouteNames.collegeSearch,
          RouteNames.assistant,
          RouteNames.communityAskSeniors,
          RouteNames.verification,
          RouteNames.home,
        ])
          GoRoute(path: path, builder: (_, s) => at(s)),
        GoRoute(path: '/community/chat/:id', builder: (_, s) => at(s)),
      ],
    );
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  group('language filter removed', () {
    testWidgets('no language bar, and guides are never filtered by language', (
      tester,
    ) async {
      await pumpGuides(tester, guides: [iit, aiims]);

      expect(find.text('All languages'), findsNothing);
      expect(find.byType(PremiumChip), findsNothing);
      expect(find.byIcon(Icons.language_outlined), findsNothing);
      expect(languagesAsked, isNotEmpty);
      expect(languagesAsked.every((l) => l == null), isTrue);
    });
  });

  group('search', () {
    // One scenario per test: re-pumping the app inside a test would reuse the
    // existing provider scope and keep its stale values.
    testWidgets('a search bar is on top while the guides are loading', (
      tester,
    ) async {
      final pending = Completer<List<PublicGuideProfile>>();
      await pumpGuides(tester, load: () => pending.future, settle: false);

      expect(find.byType(ListSkeletonLoader), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search guides by college or stream'), findsOneWidget);
      pending.complete([iit]);
      await tester.pumpAndSettle();
    });

    testWidgets('a search bar is on top when there are guides', (tester) async {
      await pumpGuides(tester, guides: [iit]);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search guides by college or stream'), findsOneWidget);
    });

    testWidgets('a search bar is on top when there are no guides', (
      tester,
    ) async {
      await pumpGuides(tester);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a search bar is on top when loading fails', (tester) async {
      await pumpGuides(tester, load: () async => throw Exception('boom'));
      expect(find.byType(AsyncErrorView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('finds guides by college', (tester) async {
      await pumpGuides(tester, guides: [iit, aiims]);
      await search(tester, 'iit');

      expect(find.byKey(const ValueKey('guide-iit')), findsOneWidget);
      expect(find.byKey(const ValueKey('guide-aiims')), findsNothing);
      expect(find.text('1 guide for “iit”'), findsOneWidget);
    });

    testWidgets('finds guides by stream, even when the course never names '
        'it', (tester) async {
      await pumpGuides(tester, guides: [iit, aiims]);

      await search(tester, 'engineering'); // B.Tech Computer Science
      expect(find.byKey(const ValueKey('guide-iit')), findsOneWidget);
      expect(find.byKey(const ValueKey('guide-aiims')), findsNothing);

      await search(tester, 'medical'); // MBBS
      expect(find.byKey(const ValueKey('guide-aiims')), findsOneWidget);
      expect(find.byKey(const ValueKey('guide-iit')), findsNothing);
    });

    testWidgets('the clear button restores the full list', (tester) async {
      await pumpGuides(tester, guides: [iit, aiims]);
      await search(tester, 'iit');
      expect(find.byKey(const ValueKey('guide-aiims')), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.byKey(const ValueKey('guide-aiims')), findsOneWidget);
      expect(find.byKey(const ValueKey('guide-iit')), findsOneWidget);
    });
  });

  group('available guides', () {
    testWidgets('are listed directly, online guides first', (tester) async {
      await pumpGuides(tester, guides: [iit, aiims]);

      expect(find.text('Available guides'), findsOneWidget);
      final online = tester.getTopLeft(
        find.byKey(const ValueKey('guide-aiims')),
      );
      final offline = tester.getTopLeft(
        find.byKey(const ValueKey('guide-iit')),
      );
      expect(online.dy, lessThan(offline.dy));
      // ...and no help/empty section when there is something to show.
      expect(find.textContaining('No guides'), findsNothing);
    });

    testWidgets('tapping a guide opens their profile', (tester) async {
      await pumpGuides(tester, guides: [iit]);
      await tester.tap(find.byKey(const ValueKey('guide-iit')));
      await tester.pumpAndSettle();
      expect(find.text('AT /guides/iit'), findsOneWidget);
    });
  });

  group('never a dead-end empty state', () {
    testWidgets('no guides at all: call-to-action cards instead of a blank '
        '"No guides available yet" card', (tester) async {
      await pumpGuides(tester);

      expect(find.text('No guides available yet'), findsNothing);
      expect(find.byType(AsyncEmptyView), findsNothing);
      expect(find.text('No guides are online right now'), findsOneWidget);
      for (final cta in [
        'Browse colleges',
        'Ask seniors',
        'Ask the AI Assistant',
        'Become a guide',
      ]) {
        expect(find.text(cta), findsOneWidget, reason: cta);
      }
      // The search bar is there to try anyway.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a search with no match explains it and offers next steps, '
        'including searching colleges for that text', (tester) async {
      await pumpGuides(tester, guides: [iit, aiims]);
      await search(tester, 'zzzz');

      expect(find.text('No guides match “zzzz”'), findsOneWidget);
      expect(find.text('Search colleges for “zzzz”'), findsOneWidget);
      expect(find.text('Browse colleges'), findsOneWidget);
      expect(find.text('No guides available yet'), findsNothing);

      await tester.tap(find.text('Show all guides'));
      await tester.pump();
      expect(find.byKey(const ValueKey('guide-iit')), findsOneWidget);
    });

    testWidgets('the CTAs go somewhere real', (tester) async {
      Future<void> tapAndExpect(String cta, String location) async {
        await pumpGuides(tester);
        await tester.tap(find.text(cta));
        await tester.pumpAndSettle();
        expect(find.text('AT $location'), findsOneWidget, reason: cta);
      }

      await tapAndExpect('Browse colleges', RouteNames.collegeSearch);
      await tapAndExpect('Ask seniors', RouteNames.communityAskSeniors);
      await tapAndExpect('Ask the AI Assistant', RouteNames.assistant);
      await tapAndExpect('Become a guide', RouteNames.verification);
    });

    testWidgets('"Search colleges for ..." carries the typed text', (
      tester,
    ) async {
      await pumpGuides(tester, guides: [iit]);
      await search(tester, 'nit trichy');
      await tester.tap(find.text('Search colleges for “nit trichy”'));
      await tester.pumpAndSettle();
      expect(
        find.text('AT ${RouteNames.collegeSearch}?q=nit+trichy'),
        findsOneWidget,
      );
    });
  });

  group('recent chats', () {
    final chats = [
      chat('c1', 'Priya', DateTime(2026, 9, 21, 9), 'oldest'),
      chat('c2', 'Karan', DateTime(2026, 9, 21, 12), 'newest'),
      chat('c3', 'Meera', DateTime(2026, 9, 21, 11), 'middle'),
      chat('c4', 'Dev', DateTime(2026, 9, 21, 10), 'older'),
    ];

    testWidgets('the three most recent conversations appear above the '
        'guides, newest first', (tester) async {
      await pumpGuides(tester, guides: [iit], chats: chats);

      expect(find.text('Recent chats'), findsOneWidget);
      expect(find.byKey(const ValueKey('recent-chat-c2')), findsOneWidget);
      expect(find.byKey(const ValueKey('recent-chat-c3')), findsOneWidget);
      expect(find.byKey(const ValueKey('recent-chat-c4')), findsOneWidget);
      expect(find.byKey(const ValueKey('recent-chat-c1')), findsNothing);

      final y = [
        for (final id in ['c2', 'c3', 'c4'])
          tester.getTopLeft(find.byKey(ValueKey('recent-chat-$id'))).dy,
      ];
      expect(y, orderedEquals([...y]..sort()));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('guide-iit'))).dy,
        greaterThan(y.last),
      );
      // Uses the other person's name as the title.
      expect(find.text('Karan'), findsOneWidget);
      expect(find.text('newest'), findsOneWidget);
    });

    testWidgets('are also shown when there are no guides', (tester) async {
      await pumpGuides(tester, chats: chats);
      expect(find.text('Recent chats'), findsOneWidget);
      expect(find.text('No guides are online right now'), findsOneWidget);
    });

    testWidgets('tapping one opens that chat; "See all" opens the Chats list', (
      tester,
    ) async {
      await pumpGuides(tester, guides: [iit], chats: chats);
      await tester.tap(find.byKey(const ValueKey('recent-chat-c2')));
      await tester.pumpAndSettle();
      expect(find.text('AT /community/chat/c2'), findsOneWidget);

      await pumpGuides(tester, guides: [iit], chats: chats);
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(
        find.text('AT ${RouteNames.communityPrivateChats}'),
        findsOneWidget,
      );
    });

    testWidgets('are hidden while searching', (tester) async {
      await pumpGuides(tester, guides: [iit], chats: chats);
      expect(find.text('Recent chats'), findsOneWidget);
      await search(tester, 'iit');
      expect(find.text('Recent chats'), findsNothing);
    });

    testWidgets('are absent when there are no chats', (tester) async {
      await pumpGuides(tester, guides: [iit]);
      expect(find.text('Recent chats'), findsNothing);
    });
  });

  group('Messages', () {
    testWidgets('the app bar Messages button goes straight to the main Chats '
        'list', (tester) async {
      await pumpGuides(tester, guides: [iit]);
      await tester.tap(find.byTooltip('Messages'));
      await tester.pumpAndSettle();
      expect(
        find.text('AT ${RouteNames.communityPrivateChats}'),
        findsOneWidget,
      );
    });
  });
}
