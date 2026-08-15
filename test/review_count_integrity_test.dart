// Regression test for the "card shows N reviews but Reviews tab is empty"
// bug.
//
// Root cause: the offline/quota-fallback bundled college dataset shipped a
// fabricated `reviewCount` / `aggregatedRatings` (e.g. college_002 showed
// "4.8 (2491 reviews)") that had no backing documents in the `reviews`
// Firestore collection at all — the number was invented at data-generation
// time (see tools/generate_colleges.py) and never reconciled with real
// review documents. Any college sourced from that fallback would show a
// nonzero review count on its card while the Reviews tab (which reads real
// `reviews` docs via FirestoreReviewService) legitimately found nothing.
//
// Fix: `colleges_seed.json` (the fabricated dataset) is no longer loaded by
// CollegeBundledDataSource or CollegeSeedService, and the real-named
// fallback (`prominent_colleges_seed.json`) has its review stats zeroed
// since College Reality has no verified reviews for those entries either.
// This test guards against reintroducing fabricated review data into the
// bundled/offline path.
import 'package:college_reality_india/core/data/college_bundled_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bundled college dataset never fabricates reviews', () {
    test('no bundled college reports a nonzero reviewCount', () async {
      final all = await CollegeBundledDataSource.loadAll();
      expect(all, isNotEmpty);

      final withFakeReviews =
          all.where((c) => c.reviewCount > 0).map((c) => '${c.id}:${c.name}');

      expect(
        withFakeReviews,
        isEmpty,
        reason:
            'Bundled/offline colleges must never advertise a review count '
            'that has no backing review documents. Offenders: '
            '${withFakeReviews.join(', ')}',
      );
    });

    test('the fully-synthetic generated dataset is excluded', () async {
      final all = await CollegeBundledDataSource.loadAll();
      // colleges_seed.json used fake "college_NNN" ids for entirely
      // invented institutions (e.g. "Global Mumbai Institute of
      // Technology"). None of those ids should ever surface in the app.
      final fakeGeneratedIds =
          all.where((c) => RegExp(r'^college_\d{3}$').hasMatch(c.id));
      expect(fakeGeneratedIds, isEmpty);
    });

    test('trending/top-rated fallback sorting never surfaces fake stats',
        () async {
      final trending = await CollegeBundledDataSource.trendingFallback();
      final topRated = await CollegeBundledDataSource.topRatedFallback();
      for (final college in [...trending, ...topRated]) {
        expect(
          college.reviewCount,
          0,
          reason: '${college.name} (${college.id}) must not show a '
              'fabricated review count in fallback surfaces.',
        );
      }
    });
  });
}
