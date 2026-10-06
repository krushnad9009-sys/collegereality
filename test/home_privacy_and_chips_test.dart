import 'package:college_reality_india/core/constants/display_name_constants.dart';
import 'package:college_reality_india/core/constants/verification_constants.dart';
import 'package:college_reality_india/core/services/search_history_service.dart';
import 'package:college_reality_india/core/utils/display_text_quality.dart';
import 'package:college_reality_india/features/auth/models/user_model.dart';
import 'package:college_reality_india/features/communication/models/public_guide_profile.dart';
import 'package:college_reality_india/features/communication/models/public_student_profile.dart';
import 'package:college_reality_india/features/communication/models/guide_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 6);

  group('PublicGuideProfile.fromUser shows the chosen public name', () {
    UserModel guide({
      required String mode,
      String? publicDisplayName,
      String? customDisplayName,
    }) =>
        UserModel(
          uid: 'guide-1',
          email: 'g@test.com',
          displayName: 'Rahul Real Name',
          displayNameMode: mode,
          publicDisplayName: publicDisplayName,
          customDisplayName: customDisplayName,
          verificationBadge: VerificationConstants.badgeVerifiedStudent,
          createdAt: now,
          updatedAt: now,
        );

    test('anonymous mode never exposes the real name', () {
      final name = PublicGuideProfile.fromUser(
        guide(mode: DisplayNameConstants.modeAnonymousVerifiedStudent),
      ).displayName;
      expect(name, isNot(contains('Rahul')));
      expect(name, startsWith(DisplayNameConstants.anonymousVerifiedStudentLabel));
    });

    test('stored publicDisplayName wins', () {
      expect(
        PublicGuideProfile.fromUser(guide(
          mode: DisplayNameConstants.modeAnonymousVerifiedStudent,
          publicDisplayName: 'Anonymous Verified Student #42',
        )).displayName,
        'Anonymous Verified Student #42',
      );
    });

    test('custom mode shows the custom name', () {
      expect(
        PublicGuideProfile.fromUser(guide(
          mode: DisplayNameConstants.modeCustom,
          customDisplayName: 'CampusSenior',
        )).displayName,
        'CampusSenior',
      );
    });

    test('real-name mode still shows the real name', () {
      expect(
        PublicGuideProfile.fromUser(
          guide(mode: DisplayNameConstants.modeRealName),
        ).displayName,
        'Rahul Real Name',
      );
    });
  });

  test('PublicStudentProfile.fromUser hides the real name behind an alias', () {
    final user = UserModel(
      uid: 'stu-1',
      email: 's@test.com',
      displayName: 'Priya Real Name',
      displayNameMode: DisplayNameConstants.modeAnonymousVerifiedStudent,
      verificationBadge: VerificationConstants.badgeVerifiedStudent,
      communicationSettings:
          const GuideCommunicationSettings(allowPublicProfile: true),
      createdAt: now,
      updatedAt: now,
    );
    final name = PublicStudentProfile.fromUser(user).displayName;
    expect(name, isNot(contains('Priya')));
    expect(name, startsWith(DisplayNameConstants.anonymousVerifiedStudentLabel));
  });

  group('isPresentableText', () {
    test('rejects test junk', () {
      for (final junk in ['hi,,,buddy', '...', 'a', '   ', 'ok!!!', '----']) {
        expect(isPresentableText(junk), isFalse, reason: junk);
      }
    });

    test('keeps real queries and copy', () {
      for (final ok in [
        'IIT Bombay',
        'B.Tech Pune',
        'MBA - Bangalore',
        'Fees < 5L?',
        'Best college, great hostel',
        'पुणे कॉलेज',
      ]) {
        expect(isPresentableText(ok), isTrue, reason: ok);
      }
    });
  });

  group('SearchHistoryService', () {
    test('drops junk on save and on read; removeSearch deletes one', () async {
      SharedPreferences.setMockInitialValues({
        'recent_college_searches': ['hi,,,buddy', 'IIT Bombay'],
      });
      final service = SearchHistoryService();

      expect(await service.getRecentSearches(), ['IIT Bombay']);

      await service.addSearch('...');
      await service.addSearch('NIT Trichy');
      expect(await service.getRecentSearches(), ['NIT Trichy', 'IIT Bombay']);

      await service.removeSearch('iit bombay');
      expect(await service.getRecentSearches(), ['NIT Trichy']);
    });
  });
}
