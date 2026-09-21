import 'package:college_reality_india/core/constants/profile_constants.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:college_reality_india/features/communication/models/public_guide_profile.dart';
import 'package:college_reality_india/features/communication/utils/guide_search_matcher.dart';
import 'package:college_reality_india/features/community/models/user_presence_model.dart';
import 'package:flutter_test/flutter_test.dart';

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
    languagesKnown: const ['English'],
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

List<String> uids(Iterable<PublicGuideProfile> guides) =>
    guides.map((g) => g.uid).toList();

void main() {
  group('tokens / streamsOf', () {
    test('dots vanish and punctuation separates words', () {
      expect(GuideSearchMatcher.tokens('B.Tech (CSE)'), ['btech', 'cse']);
      expect(GuideSearchMatcher.tokens('  '), isEmpty);
    });

    test('a bare course still belongs to its stream', () {
      expect(GuideSearchMatcher.streamsOf('B.Tech'), {'Engineering'});
      expect(GuideSearchMatcher.streamsOf('MBBS'), {'Medical'});
      expect(GuideSearchMatcher.streamsOf('MBA Finance'), contains('MBA'));
      expect(GuideSearchMatcher.streamsOf('LLB'), {'Law'});
    });

    test('a course can belong to more than one stream', () {
      expect(GuideSearchMatcher.streamsOf('Computer Science'), {
        'Engineering',
        'Science',
      });
      expect(GuideSearchMatcher.streamsOf('B.Sc Nursing'), {
        'Science',
        'Nursing',
      });
    });

    test(
      'short course codes only match as whole words ("ba" is not in "mba")',
      () {
        expect(GuideSearchMatcher.streamsOf('MBA'), {'MBA'});
        expect(GuideSearchMatcher.streamsOf('BA Economics'), contains('Arts'));
      },
    );

    test('no course -> no stream', () {
      expect(GuideSearchMatcher.streamsOf(null), isEmpty);
      expect(GuideSearchMatcher.streamsOf('  '), isEmpty);
    });
  });

  group('matches', () {
    final iit = guide(
      'a',
      'Aisha',
      college: 'IIT Bombay',
      course: 'B.Tech Computer Science',
    );
    final aiims = guide('b', 'Rahul', college: 'AIIMS Delhi', course: 'MBBS');

    test('a blank query matches everyone', () {
      expect(GuideSearchMatcher.matches(iit, ''), isTrue);
      expect(GuideSearchMatcher.matches(iit, '   '), isTrue);
    });

    test('by college, case-insensitively and by word prefix', () {
      expect(GuideSearchMatcher.matches(iit, 'iit'), isTrue);
      expect(GuideSearchMatcher.matches(iit, 'BOMB'), isTrue);
      expect(GuideSearchMatcher.matches(iit, 'delhi'), isFalse);
      expect(GuideSearchMatcher.matches(aiims, 'delhi'), isTrue);
    });

    test('by stream, even when the course text never says it', () {
      // Course is "B.Tech Computer Science" -- never the word "engineering".
      expect(GuideSearchMatcher.matches(iit, 'engineering'), isTrue);
      expect(GuideSearchMatcher.matches(aiims, 'medical'), isTrue);
      expect(GuideSearchMatcher.matches(aiims, 'engineering'), isFalse);
    });

    test('by course text and by name', () {
      expect(GuideSearchMatcher.matches(iit, 'computer'), isTrue);
      expect(GuideSearchMatcher.matches(aiims, 'rah'), isTrue);
    });

    test('every typed word must match something', () {
      expect(GuideSearchMatcher.matches(iit, 'iit engineering'), isTrue);
      expect(GuideSearchMatcher.matches(iit, 'iit medical'), isFalse);
      expect(GuideSearchMatcher.matches(iit, 'bombay btech'), isTrue);
    });

    test('a mid-word fragment is not a match', () {
      expect(GuideSearchMatcher.matches(iit, 'ombay'), isFalse);
    });

    test('guides with no college/course only match by name', () {
      final bare = guide('c', 'Priya');
      expect(GuideSearchMatcher.matches(bare, 'priya'), isTrue);
      expect(GuideSearchMatcher.matches(bare, 'engineering'), isFalse);
    });

    test('filter keeps the input order', () {
      final list = [iit, aiims, guide('d', 'Zed', college: 'IIT Madras')];
      expect(uids(GuideSearchMatcher.filter(list, 'iit')), ['a', 'd']);
    });
  });

  group('sortByAvailability', () {
    test('online first, then better rated, then more ratings, then name', () {
      final sorted = GuideSearchMatcher.sortByAvailability([
        guide('offline-top', 'Zoe', rating: 4.9, ratings: 50),
        guide('online-low', 'Yan', online: true, rating: 3.0, ratings: 2),
        guide('offline-b', 'Bob', rating: 4.0, ratings: 10),
        guide('offline-a', 'Amy', rating: 4.0, ratings: 10),
        guide('offline-many', 'Cat', rating: 4.0, ratings: 30),
        guide('online-high', 'Xen', online: true, rating: 4.5, ratings: 9),
      ]);
      expect(uids(sorted), [
        'online-high',
        'online-low',
        'offline-top',
        'offline-many',
        'offline-a',
        'offline-b',
      ]);
    });

    test('does not mutate its input', () {
      final input = [guide('x', 'X', rating: 1), guide('y', 'Y', online: true)];
      GuideSearchMatcher.sortByAvailability(input);
      expect(uids(input), ['x', 'y']);
    });
  });
}
