import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/auth/providers/auth_provider.dart';
import 'package:college_reality_india/features/auth/providers/user_provider.dart';
import 'package:college_reality_india/features/personalization/models/user_preferences.dart';
import 'package:college_reality_india/features/personalization/providers/user_preferences_provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  UserModel user({
    String? state,
    String? preferredState,
    String? preferredCategory,
    Map<String, int> counts = const {},
  }) => UserModel(
    uid: 'u1',
    email: 'a@b.com',
    state: state,
    preferredState: preferredState,
    preferredCategory: preferredCategory,
    categoryInteractionCounts: counts,
    createdAt: now,
    updatedAt: now,
  );

  group('UserPreferences.fromUser', () {
    test('no user → empty', () {
      expect(UserPreferences.fromUser(null).isEmpty, isTrue);
    });

    test('falls back to the state detected at onboarding', () {
      final prefs = UserPreferences.fromUser(user(state: 'Maharashtra'));
      expect(prefs.preferredState, 'Maharashtra');
    });

    test('an explicit preferredState beats the detected one', () {
      final prefs = UserPreferences.fromUser(
        user(state: 'Maharashtra', preferredState: 'Karnataka'),
      );
      expect(prefs.preferredState, 'Karnataka');
    });

    test('the "Not Provided" sentinel is never a state', () {
      final prefs = UserPreferences.fromUser(user(state: 'Not Provided'));
      expect(prefs.hasState, isFalse);
      expect(prefs.isEmpty, isTrue);
    });

    test('a stored category outside the allowed list is dropped', () {
      final prefs = UserPreferences.fromUser(user(preferredCategory: 'Basket'));
      expect(prefs.hasCategory, isFalse);
    });
  });

  group('withCategoryInteraction', () {
    test('first interaction becomes the favourite', () {
      final prefs = UserPreferences.empty.withCategoryInteraction('Arts');
      expect(prefs.preferredCategory, 'Arts');
      expect(prefs.categoryCounts, {'Arts': 1});
    });

    test('most frequent stream wins, not the most recent', () {
      var prefs = UserPreferences.empty;
      for (final c in ['Arts', 'Arts', 'Arts', 'Engineering']) {
        prefs = prefs.withCategoryInteraction(c);
      }
      expect(prefs.preferredCategory, 'Arts');
    });

    test('a tie goes to the stream just used', () {
      var prefs = UserPreferences.empty;
      for (final c in ['Arts', 'Arts', 'Engineering', 'Engineering']) {
        prefs = prefs.withCategoryInteraction(c);
      }
      expect(prefs.preferredCategory, 'Engineering');
    });

    test('does not mutate the previous instance', () {
      const before = UserPreferences(categoryCounts: {'Arts': 1});
      before.withCategoryInteraction('Arts');
      expect(before.categoryCounts, {'Arts': 1});
    });
  });

  group('UserModel persistence shape', () {
    test('round-trips the preference fields', () {
      final restored = UserModel.fromJson(
        user(
          preferredState: 'Goa',
          preferredCategory: 'Law',
          counts: {'Law': 3},
        ).toJson(),
      );
      expect(restored.preferredState, 'Goa');
      expect(restored.preferredCategory, 'Law');
      expect(restored.categoryInteractionCounts, {'Law': 3});
    });

    test('legacy docs without the fields still parse', () {
      final json = user().toJson()
        ..remove('preferredState')
        ..remove('preferredCategory')
        ..remove('categoryInteractionCounts');
      final restored = UserModel.fromJson(json);
      expect(restored.preferredState, isNull);
      expect(restored.categoryInteractionCounts, isEmpty);
    });

    test('tolerates double counters and junk entries', () {
      final json = user().toJson()
        ..['categoryInteractionCounts'] = {'Arts': 2.0, 'Law': 'x', 'MBA': 0};
      expect(UserModel.fromJson(json).categoryInteractionCounts, {'Arts': 2});
    });
  });

  group('UserPreferencesNotifier', () {
    late FakeUserRepository repo;

    Future<ProviderContainer> containerFor({
      required bool signedIn,
      UserModel? doc,
    }) async {
      repo = FakeUserRepository();
      if (doc != null) repo.users[doc.uid] = doc;
      final mockUser = MockUser(uid: 'u1', email: 'a@b.com');
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWith((ref) => signedIn ? mockUser : null),
          currentUserDetailProvider.overrideWith((ref) async => doc),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserDetailProvider.future);
      return container;
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('seeds from the stored user doc', () async {
      final c = await containerFor(
        signedIn: true,
        doc: user(preferredCategory: 'Arts', state: 'Maharashtra'),
      );
      final prefs = c.read(userPreferencesProvider);
      expect(prefs.preferredCategory, 'Arts');
      expect(prefs.preferredState, 'Maharashtra');
    });

    test(
      'a category filter updates state and persists count + favourite',
      () async {
        final c = await containerFor(signedIn: true, doc: user());
        c.read(userPreferencesProvider.notifier).recordSearch(category: 'Arts');
        await settle();

        expect(c.read(userPreferencesProvider).preferredCategory, 'Arts');
        expect(repo.users['u1']!.preferredCategory, 'Arts');
        expect(repo.users['u1']!.categoryInteractionCounts, {'Arts': 1});
      },
    );

    test('a course-only filter counts toward its stream', () async {
      final c = await containerFor(signedIn: true, doc: user());
      c.read(userPreferencesProvider.notifier).recordSearch(course: 'B.Tech');
      await settle();

      expect(c.read(userPreferencesProvider).preferredCategory, 'Engineering');
    });

    test('free text naming a stream counts; free-text state does not move '
        'the preferred state', () async {
      final c = await containerFor(signedIn: true, doc: user());
      c
          .read(userPreferencesProvider.notifier)
          .recordSearch(query: 'Engineering Maharashtra');
      await settle();

      final prefs = c.read(userPreferencesProvider);
      expect(prefs.preferredCategory, 'Engineering');
      expect(prefs.hasState, isFalse);
    });

    test(
      'an explicit state filter is stored once, not on every repeat',
      () async {
        final c = await containerFor(signedIn: true, doc: user());
        final notifier = c.read(userPreferencesProvider.notifier);
        notifier.recordSearch(state: 'Karnataka');
        await settle();
        expect(repo.users['u1']!.preferredState, 'Karnataka');

        // Repeat with a different case: no state change, no second write.
        repo.users['u1'] = repo.users['u1']!.copyWith(preferredState: 'MARKER');
        notifier.recordSearch(state: 'karnataka');
        await settle();
        expect(repo.users['u1']!.preferredState, 'MARKER');
      },
    );

    test('"General", unknown streams and the sentinel are ignored', () async {
      final c = await containerFor(signedIn: true, doc: user());
      final notifier = c.read(userPreferencesProvider.notifier);
      notifier.recordCategory('General');
      notifier.recordCategory('Basket');
      notifier.recordCategory(null);
      notifier.recordState('Not Provided');
      await settle();

      expect(c.read(userPreferencesProvider).isEmpty, isTrue);
      expect(repo.users['u1']!.categoryInteractionCounts, isEmpty);
    });

    test(
      'guests keep preferences for the session but persist nothing',
      () async {
        final c = await containerFor(signedIn: false);
        c.read(userPreferencesProvider.notifier).recordSearch(category: 'Law');
        await settle();

        expect(c.read(userPreferencesProvider).preferredCategory, 'Law');
        expect(repo.users, isEmpty);
      },
    );

    test('a failing write never surfaces to the caller', () async {
      final throwing = _ThrowingRepo();
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(throwing),
          currentUserProvider.overrideWith(
            (ref) => MockUser(uid: 'u1', email: 'a@b.com'),
          ),
          currentUserDetailProvider.overrideWith((ref) async => user()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserDetailProvider.future);

      expect(
        () => container
            .read(userPreferencesProvider.notifier)
            .recordSearch(category: 'Arts'),
        returnsNormally,
      );
      await settle();
      // Optimistic state is kept even though persisting failed.
      expect(container.read(userPreferencesProvider).preferredCategory, 'Arts');
    });
  });
}

class _ThrowingRepo extends FakeUserRepository {
  @override
  Future<void> recordCategoryInteraction(
    String uid, {
    required String category,
    required String preferredCategory,
  }) {
    throw StateError('boom');
  }
}
