import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';

/// Lightweight markdown-style formatting: **bold**, *italic*, - bullets, @[Name](uid) mentions.
class QuestionRichTextUtils {
  QuestionRichTextUtils._();

  static String wrapBold(String text) => '**$text**';
  static String wrapItalic(String text) => '*$text*';
  static String bulletLine(String text) => '- $text';
  static String mentionToken(String displayName, String userId) =>
      '@[$displayName]($userId)';

  static List<InlineSpan> parseToSpans(
    String text, {
    TextStyle? baseStyle,
    void Function(String userId)? onMentionTap,
  }) {
    final style = baseStyle ??
        GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppTheme.gray800);
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      var line = lines[i];
      final isBullet = line.startsWith('- ');
      if (isBullet) {
        spans.add(TextSpan(
          text: '• ',
          style: style.copyWith(fontWeight: FontWeight.w700),
        ));
        line = line.substring(2);
      }
      spans.addAll(_parseInline(line, style: style, onMentionTap: onMentionTap));
    }
    return spans;
  }

  static Widget buildRichText(
    String text, {
    int? maxLines,
    TextStyle? baseStyle,
    void Function(String userId)? onMentionTap,
  }) {
    return Text.rich(
      TextSpan(
        children: parseToSpans(
          text,
          baseStyle: baseStyle,
          onMentionTap: onMentionTap,
        ),
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  static List<InlineSpan> _parseInline(
    String line, {
    required TextStyle style,
    void Function(String userId)? onMentionTap,
  }) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*(.+?)\*\*|\*(.+?)\*|@\[(.+?)\]\((.+?)\))',
    );
    var start = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > start) {
        spans.add(TextSpan(text: line.substring(start, match.start), style: style));
      }
      final full = match.group(0)!;
      if (full.startsWith('**')) {
        spans.add(TextSpan(
          text: match.group(2),
          style: style.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (full.startsWith('*')) {
        spans.add(TextSpan(
          text: match.group(3),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (full.startsWith('@[')) {
        final name = match.group(4) ?? 'User';
        final uid = match.group(5) ?? '';
        spans.add(TextSpan(
          text: '@$name',
          style: style.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          recognizer: onMentionTap != null && uid.isNotEmpty
              ? (TapGestureRecognizer()..onTap = () => onMentionTap(uid))
              : null,
        ));
      }
      start = match.end;
    }
    if (start < line.length) {
      spans.add(TextSpan(text: line.substring(start), style: style));
    }
    return spans;
  }
}
