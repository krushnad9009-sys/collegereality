import 'package:college_reality_india/core/constants/careers_constants.dart';
import 'package:college_reality_india/features/careers/models/careers_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('InternshipModel JSON and getters', () {
    final model = InternshipModel(
      id: 'i1',
      title: 'SDE Intern',
      companyId: 'c1',
      companyName: 'Acme',
      city: 'Pune',
      payType: CareersConstants.payTypePaid,
      workType: CareersConstants.workTypeRemote,
      createdAt: now,
      updatedAt: now,
    );
    expect(model.isPaid, isTrue);
    expect(model.isRemote, isTrue);
    final restored = InternshipModel.fromJson(model.toJson());
    expect(restored.title, 'SDE Intern');
    expect(restored.companyName, 'Acme');
  });

  test('InternshipModel fromJson defaults', () {
    final restored = InternshipModel.fromJson({'title': 'X'}, docId: 'id');
    expect(restored.id, 'id');
    expect(restored.isPaid, isTrue);
  });
}