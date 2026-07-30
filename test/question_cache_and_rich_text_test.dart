import 'package:college_reality_india/core/constants/question_constants.dart';
import 'package:college_reality_india/features/questions/models/question_model.dart';
import 'package:college_reality_india/features/questions/services/question_cache_service.dart';
import 'package:college_reality_india/features/questions/utils/question_rich_text_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuestionModel _question({required String id, required String collegeId}) {
  final now = DateTime(2026, 2, 1);
  return QuestionModel(
    id: id,
    collegeId: collegeId,
    collegeName: 'Test College',
    authorId: 'author-1',
    authorDisplayName: 'Student',
    title: 'Question $id',
    body: 'Body for $id',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuestionCacheService', () {
    test('saveCollegeQuestions and loadCollegeQuestions round-trip', () async {
      final questions = [
        _question(id: 'q1', collegeId: 'col-1'),
        _question(id: 'q2', collegeId: 'col-1'),
      ];

      await QuestionCacheService.saveCollegeQuestions('col-1', questions);
      final loaded = await QuestionCacheService.loadCollegeQuestions('col-1');

      expect(loaded.length, 2);
      expect(loaded.first.id, 'q1');
      expect(loaded.last.title, 'Question q2');
    });

    test('ignores empty collegeId or empty questions', () async {
      await QuestionCacheService.saveCollegeQuestions('', [_question(id: 'q', collegeId: '')]);
      await QuestionCacheService.saveCollegeQuestions('col-1', []);
      expect(await QuestionCacheService.loadCollegeQuestions('col-1'), isEmpty);
    });

    test('returns empty for unknown college', () async {
      expect(await QuestionCacheService.loadCollegeQuestions('missing'), isEmpty);
    });

    test('limits cached questions to cacheMaxQuestions', () async {
      final many = List.generate(
        QuestionConstants.cacheMaxQuestions + 10,
        (i) => _question(id: 'q$i', collegeId: 'big-col'),
      );
      await QuestionCacheService.saveCollegeQuestions('big-col', many);
      final loaded = await QuestionCacheService.loadCollegeQuestions('big-col');
      expect(loaded.length, QuestionConstants.cacheMaxQuestions);
    });

    test('saveQuestionDetail and loadQuestionDetail round-trip', () async {
      final q = _question(id: 'detail-1', collegeId: 'col-1');
      await QuestionCacheService.saveQuestionDetail(q);
      final loaded = await QuestionCacheService.loadQuestionDetail('detail-1');
      expect(loaded?.id, 'detail-1');
      expect(loaded?.body, q.body);
    });

    test('loadQuestionDetail returns null for empty id', () async {
      expect(await QuestionCacheService.loadQuestionDetail(''), isNull);
    });

    test('loadCollegeQuestions returns empty on corrupt JSON', () async {
      SharedPreferences.setMockInitialValues({
        'qa_cache_v1_bad-col': '{not valid json',
      });
      expect(await QuestionCacheService.loadCollegeQuestions('bad-col'), isEmpty);
    });
  });

  group('QuestionRichTextUtils', () {
    test('wrap helpers produce expected markdown tokens', () {
      expect(QuestionRichTextUtils.wrapBold('text'), '**text**');
      expect(QuestionRichTextUtils.wrapItalic('text'), '*text*');
      expect(QuestionRichTextUtils.bulletLine('item'), '- item');
      expect(
        QuestionRichTextUtils.mentionToken('Priya', 'uid-1'),
        '@[Priya](uid-1)',
      );
    });

    test('parseToSpans handles bold, italic, bullets, mentions', () {
      final text = '- **Bold** and *italic* with @[Priya](uid-1)';
      final spans = QuestionRichTextUtils.parseToSpans(
        text,
        baseStyle: const TextStyle(fontSize: 14),
      );

      expect(spans.length, greaterThan(3));
      final plainTexts = spans
          .whereType<TextSpan>()
          .map((s) => s.text ?? '')
          .join();
      expect(plainTexts, contains('Bold'));
      expect(plainTexts, contains('italic'));
      expect(plainTexts, contains('@Priya'));
    });

    test('parseToSpans invokes onMentionTap for mentions', () {
      String? tappedUid;
      final spans = QuestionRichTextUtils.parseToSpans(
        'Hello @[User](user-42)',
        baseStyle: const TextStyle(fontSize: 14),
        onMentionTap: (uid) => tappedUid = uid,
      );

      final mentionSpan = spans.whereType<TextSpan>().firstWhere(
            (s) => (s.text ?? '').startsWith('@'),
          );
      expect(mentionSpan.recognizer, isNotNull);
      (mentionSpan.recognizer as TapGestureRecognizer).onTap?.call();
      expect(tappedUid, 'user-42');
    });

    test('parseToSpans preserves newlines between lines', () {
      final spans = QuestionRichTextUtils.parseToSpans(
        'Line one\nLine two',
        baseStyle: const TextStyle(fontSize: 14),
      );
      expect(
        spans.any((s) => s is TextSpan && s.text == '\n'),
        isTrue,
      );
    });

    test('buildRichText renders Text.rich widget', () {
      final widget = QuestionRichTextUtils.buildRichText(
        '**Hello**',
        baseStyle: const TextStyle(fontSize: 14),
      );
      expect(widget, isA<Text>());
    });
  });
}
