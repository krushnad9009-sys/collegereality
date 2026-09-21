import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_reality_india/core/cache/firestore_quota_guard.dart';
import 'package:college_reality_india/core/data/college_bundled_data_source.dart';
import 'package:college_reality_india/features/colleges/models/college_model.dart';
import 'package:college_reality_india/features/colleges/services/college_name_suggestion_service.dart';
import 'package:college_reality_india/features/colleges/services/firestore_college_service.dart';
import 'package:college_reality_india/features/colleges/utils/college_name_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Firestore service that never touches Firebase: runs [onSuggest] instead.
class _FakeFirestoreService extends Fake implements FirestoreCollegeService {
  final Future<List<CollegeModel>> Function(String query, int limit) onSuggest;

  _FakeFirestoreService(this.onSuggest);

  @override
  Future<List<CollegeModel>> suggestCollegesByName(
    String query, {
    int limit = 8,
  }) => onSuggest(query, limit);
}

CollegeModel _college(String name) => CollegeModel.createDraft(
  id: name,
).copyWith(name: name, nameLower: name.toLowerCase());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FirestoreQuotaGuard.instance.markRecovered());
  tearDown(() => FirestoreQuotaGuard.instance.markRecovered());

  test('constructing the service never touches Firestore', () {
    // The factory would throw if it were called.
    expect(
      () => CollegeNameSuggestionService(() => throw StateError('no Firebase')),
      returnsNormally,
    );
  });

  test('online: returns what the Firestore name query returned', () async {
    String? askedQuery;
    int? askedLimit;
    final service = CollegeNameSuggestionService(
      () => _FakeFirestoreService((q, limit) async {
        askedQuery = q;
        askedLimit = limit;
        return [_college('Jain College')];
      }),
    );

    final result = await service.suggest('ja', limit: 5);
    expect(result.map((c) => c.name), ['Jain College']);
    expect(askedQuery, 'ja');
    expect(askedLimit, 5);
  });

  test('over quota (guard tripped): answers from the bundled colleges, by '
      'NAME, without going online', () async {
    final bundled = await CollegeBundledDataSource.loadAll();
    expect(bundled, isNotEmpty);
    final prefix = bundled.first.name.substring(0, 4);

    FirestoreQuotaGuard.instance.markQuotaExceeded();
    final service = CollegeNameSuggestionService(
      () => throw StateError('must not go online while blocked'),
    );

    final result = await service.suggest(prefix);
    expect(result, isNotEmpty);
    for (final college in result) {
      expect(
        CollegeNameMatcher.matches(prefix, college),
        isTrue,
        reason: '${college.name} must match "$prefix" by name',
      );
    }
  });

  test(
    'a quota error mid-request falls back to the bundled colleges',
    () async {
      final bundled = await CollegeBundledDataSource.loadAll();
      final prefix = bundled.first.name.substring(0, 4);

      final service = CollegeNameSuggestionService(
        () => _FakeFirestoreService(
          (q, limit) async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'resource-exhausted',
          ),
        ),
      );

      final result = await service.suggest(prefix);
      expect(result, isNotEmpty);
      expect(FirestoreQuotaGuard.instance.isBlocked, isTrue);
    },
  );

  test('any other Firestore error is rethrown (the dropdown then falls back '
      'to states/cities)', () async {
    final service = CollegeNameSuggestionService(
      () => _FakeFirestoreService(
        (q, limit) async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      ),
    );

    expect(() => service.suggest('ja'), throwsA(isA<FirebaseException>()));
  });
}
