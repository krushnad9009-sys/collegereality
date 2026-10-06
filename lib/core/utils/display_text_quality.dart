/// Guards for user/admin-entered text shown as chips or cards: keeps
/// keyboard-mash and test entries (e.g. "hi,,,buddy", "...", "a") off the
/// UI without trying to judge real content.
final RegExp _alnum = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Three or more of the same non-letter/digit/space character in a row.
final RegExp _punctuationRun = RegExp(r'([^\p{L}\p{N}\s])\1{2,}', unicode: true);

/// True when [text] is worth showing: at least [minAlnum] letters/digits
/// and no runs like ",,," or "!!!".
bool isPresentableText(String text, {int minAlnum = 2}) {
  final t = text.trim();
  if (t.isEmpty) return false;
  if (_alnum.allMatches(t).length < minAlnum) return false;
  return !_punctuationRun.hasMatch(t);
}
