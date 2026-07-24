import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/compare_constants.dart';
import '../models/saved_comparison_model.dart';

class CompareSavedService {
  CompareSavedService(this._prefs);

  final SharedPreferences _prefs;
  static const _storageKey = 'saved_comparisons_v1';
  final _uuid = const Uuid();

  List<SavedComparisonModel> readAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedComparisonModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  Future<SavedComparisonModel> save({
    required List<String> collegeIds,
    String? title,
  }) async {
    final existing = readAll();
    final normalizedIds = collegeIds.take(CompareConstants.maxColleges).toList();
    final model = SavedComparisonModel(
      id: _uuid.v4(),
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : 'Comparison (${normalizedIds.length} colleges)',
      collegeIds: normalizedIds,
      savedAt: DateTime.now(),
    );

    final next = [model, ...existing]
        .take(CompareConstants.savedComparisonLimit)
        .toList();
    await _prefs.setString(
      _storageKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
    return model;
  }

  Future<void> delete(String id) async {
    final next = readAll().where((item) => item.id != id).toList();
    await _prefs.setString(
      _storageKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}
