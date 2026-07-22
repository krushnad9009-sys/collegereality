import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/display_name_constants.dart';
import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/core/utils/public_display_name_utils.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/auth/utils/validation_util.dart';

void main() {
  group('PublicDisplayNameUtils', () {
    test('buildAnonymousVerifiedStudentAlias hides identity', () {
      final alias = buildAnonymousVerifiedStudentAlias('user-abc');
      expect(alias.startsWith('Anonymous Verified Student #'), isTrue);
    });

    test('computePublicDisplayName uses real name mode', () {
      expect(
        computePublicDisplayName(
          userId: 'u1',
          verifiedRealName: 'Rahul Sharma',
          displayNameMode: DisplayNameConstants.modeRealName,
          customDisplayName: null,
          verificationBadge: VerificationConstants.badgeVerifiedStudent,
        ),
        'Rahul Sharma',
      );
    });

    test('computePublicDisplayName uses custom name mode', () {
      expect(
        computePublicDisplayName(
          userId: 'u1',
          verifiedRealName: 'Rahul Sharma',
          displayNameMode: DisplayNameConstants.modeCustom,
          customDisplayName: 'CampusExplorer',
          verificationBadge: VerificationConstants.badgeVerifiedStudent,
        ),
        'CampusExplorer',
      );
    });

    test('canChangeDisplayName respects 90 day cooldown', () {
      final lastChanged = DateTime(2026, 1, 1);
      expect(
        canChangeDisplayName(lastChanged, now: DateTime(2026, 3, 1)),
        isFalse,
      );
      expect(
        canChangeDisplayName(lastChanged, now: DateTime(2026, 4, 2)),
        isTrue,
      );
    });

    test('resolvePublicDisplayNameFromUser prefers stored public name', () {
      final user = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        verifiedRealName: 'Private Name',
        publicDisplayName: 'Public Alias',
        displayNameMode: DisplayNameConstants.modeCustom,
        customDisplayName: 'Public Alias',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.effectivePublicDisplayName, 'Public Alias');
      expect(user.usesAnonymousPublicDisplayName, isFalse);
    });

    test('usesAnonymousPublicDisplayName is true for anonymous modes', () {
      final user = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        displayNameMode: DisplayNameConstants.modeAnonymousVerifiedStudent,
        verificationBadge: VerificationConstants.badgeVerifiedStudent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.usesAnonymousPublicDisplayName, isTrue);
    });
  });

  group('ValidationUtil custom display names', () {
    test('rejects offensive custom display names', () {
      expect(
        ValidationUtil.validateCustomDisplayName('stupid reviewer'),
        isNotNull,
      );
    });

    test('accepts valid custom display names', () {
      expect(ValidationUtil.validateCustomDisplayName('CampusExplorer'), isNull);
    });

    test('rejects reserved phrases', () {
      expect(
        ValidationUtil.validateCustomDisplayName('Super Admin'),
        isNotNull,
      );
    });
  });
}
