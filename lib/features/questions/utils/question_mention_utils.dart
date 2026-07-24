/// Parses @[Display Name](userId) mention tokens from rich text content.
class QuestionMentionUtils {
  QuestionMentionUtils._();

  static final _mentionPattern = RegExp(r'@\[[^\]]+\]\(([^)]+)\)');

  static List<String> extractMentionUserIds(String text) {
    final ids = <String>{};
    for (final match in _mentionPattern.allMatches(text)) {
      final uid = match.group(1)?.trim();
      if (uid != null && uid.isNotEmpty) ids.add(uid);
    }
    return ids.toList();
  }
}
