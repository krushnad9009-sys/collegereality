import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/ecosystem_constants.dart';
import 'package:college_reality_india/core/constants/role_constants.dart';
import 'package:college_reality_india/features/ecosystem/models/ecosystem_models.dart';
import 'package:college_reality_india/features/ecosystem/services/role_service.dart';

void main() {
  group('RoleService', () {
    test('guest when user is null', () {
      expect(RoleService.resolveRole(user: null), RoleConstants.guest);
    });

    test('canModerate for admin and moderator', () {
      expect(RoleService.canModerate(RoleConstants.admin), isTrue);
      expect(RoleService.canModerate(RoleConstants.moderator), isTrue);
      expect(RoleService.canModerate(RoleConstants.student), isFalse);
    });
  });

  group('EcosystemConstants', () {
    test('report types have labels', () {
      expect(
        EcosystemConstants.reportTypeLabel(EcosystemConstants.reportWrongFees),
        'Wrong fees',
      );
    });

    test('official sections have labels', () {
      expect(
        EcosystemConstants.sectionLabel(EcosystemConstants.sectionNotice),
        'Notice Board',
      );
    });
  });

  group('EditHistoryEntry', () {
    test('round-trips json', () {
      final entry = EditHistoryEntry(
        action: 'submitted',
        field: 'address',
        oldValue: 'Old',
        newValue: 'New',
        actorId: 'u1',
        actorName: 'Test',
        at: DateTime(2026, 1, 1),
      );
      final restored = EditHistoryEntry.fromJson(entry.toJson());
      expect(restored.field, 'address');
      expect(restored.newValue, 'New');
    });
  });
}
