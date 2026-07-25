import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_constants.dart';

class SuperAdminSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection(FirestoreConstants.adminSettingsCollection).doc('platform');

  Future<Map<String, dynamic>> loadSettings() async {
    final snap = await _settingsDoc.get();
    return snap.data() ?? {};
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    await _settingsDoc.set(
      {
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}

final superAdminSettingsServiceProvider = Provider<SuperAdminSettingsService>((ref) {
  return SuperAdminSettingsService();
});

final superAdminSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(superAdminSettingsServiceProvider).loadSettings();
});
