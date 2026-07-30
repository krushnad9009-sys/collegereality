import 'package:college_reality_india/core/constants/compare_constants.dart';
import 'package:college_reality_india/features/compare/services/compare_saved_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late CompareSavedService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = CompareSavedService(prefs);
  });

  test('readAll empty and corrupt payload', () async {
    expect(service.readAll(), isEmpty);
    await prefs.setString('saved_comparisons_v1', '{not-json');
    expect(service.readAll(), isEmpty);
  });

  test('save delete and title defaults', () async {
    final saved = await service.save(collegeIds: ['a', 'b', 'c']);
    expect(saved.collegeIds, ['a', 'b', 'c']);
    expect(saved.title, contains('Comparison'));
    expect(service.readAll(), hasLength(1));

    final titled = await service.save(
      collegeIds: List.generate(CompareConstants.maxColleges + 2, (i) => 'c$i'),
      title: '  My list  ',
    );
    expect(titled.title, 'My list');
    expect(titled.collegeIds.length, CompareConstants.maxColleges);

    await service.delete(saved.id);
    final remaining = service.readAll();
    expect(remaining.any((e) => e.id == saved.id), isFalse);
    expect(remaining.any((e) => e.id == titled.id), isTrue);
  });
}