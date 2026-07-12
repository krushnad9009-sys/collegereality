import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String rememberMeKey = 'remember_me';
  static const String savedEmailKey = 'saved_email';

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(rememberMeKey) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rememberMeKey, value);
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(savedEmailKey);
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedEmailKey, email);
  }

  Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(savedEmailKey);
  }
}

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

final savedEmailProvider = FutureProvider<String?>((ref) async {
  final prefs = ref.watch(preferencesServiceProvider);
  final rememberMe = await prefs.getRememberMe();
  if (!rememberMe) return null;
  return prefs.getSavedEmail();
});
