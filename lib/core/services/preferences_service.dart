import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String rememberMeKey = 'remember_me';
  static const String savedEmailKey = 'saved_email';

  // On web, SharedPreferences is backed by window.localStorage — plaintext
  // and readable by any script on the origin (an XSS payload included). The
  // user's email address must not live there, so "remember email" is a
  // native-only convenience; on web only the boolean flag is persisted.
  static bool get _canPersistEmail => !kIsWeb;

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(rememberMeKey) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rememberMeKey, value);
  }

  Future<String?> getSavedEmail() async {
    if (!_canPersistEmail) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(savedEmailKey);
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_canPersistEmail) {
      // Defensive: drop any value written by an older build.
      await prefs.remove(savedEmailKey);
      return;
    }
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
