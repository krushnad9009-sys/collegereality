import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/question_constants.dart';
import '../models/question_model.dart';

/// Offline cache for recently viewed college questions.
class QuestionCacheService {
  QuestionCacheService._();

  static const _prefix = 'qa_cache_v1_';

  static String _key(String collegeId) => '$_prefix${collegeId.trim()}';

  static Future<void> saveCollegeQuestions(
    String collegeId,
    List<QuestionModel> questions,
  ) async {
    if (collegeId.isEmpty || questions.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final slice = questions
        .take(QuestionConstants.cacheMaxQuestions)
        .map((q) => q.toJson())
        .toList();
    await prefs.setString(_key(collegeId), jsonEncode(slice));
  }

  static Future<List<QuestionModel>> loadCollegeQuestions(
    String collegeId,
  ) async {
    if (collegeId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(collegeId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveQuestionDetail(QuestionModel question) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}detail_${question.id}', jsonEncode(question.toJson()));
  }

  static Future<QuestionModel?> loadQuestionDetail(String questionId) async {
    if (questionId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_prefix}detail_$questionId');
    if (raw == null) return null;
    try {
      return QuestionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
