/// Sanitizes user text for display and storage.
/// Invisible / direction-changing characters used to spoof text (e.g. a
/// right-to-left override making "evil.exe" read "exe.live"), plus other
/// control characters. Newlines/tabs are whitespace and handled below.
final RegExp _invisibleOrControl = RegExp(
  '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F'
  '\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
);

String sanitizeUserContent(String text, {int maxLength = 2000}) {
  var result = text.replaceAll(_invisibleOrControl, '').trim();
  result = result.replaceAll(RegExp(r'\s+'), ' ');
  if (result.length > maxLength) {
    result = result.substring(0, maxLength);
  }
  return result;
}

/// Returns true when content is empty after sanitization.
bool isEmptyContent(String text) => sanitizeUserContent(text).isEmpty;

/// Builds a short preview for feed cards.
String buildContentPreview(String text, {int maxChars = 120}) {
  final sanitized = sanitizeUserContent(text);
  if (sanitized.length <= maxChars) return sanitized;
  return '${sanitized.substring(0, maxChars)}…';
}
