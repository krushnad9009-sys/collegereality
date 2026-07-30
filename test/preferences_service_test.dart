import 'package:college_reality_india/core/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreferencesService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = PreferencesService();
  });

  test('remember me defaults false and can be toggled', () async {
    expect(await service.getRememberMe(), isFalse);
    await service.setRememberMe(true);
    expect(await service.getRememberMe(), isTrue);
  });

  test('save and clear email', () async {
    expect(await service.getSavedEmail(), isNull);
    await service.saveEmail('student@test.com');
    expect(await service.getSavedEmail(), 'student@test.com');
    await service.clearSavedEmail();
    expect(await service.getSavedEmail(), isNull);
  });
}