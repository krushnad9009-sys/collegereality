/// Sanitizes user text for display and storage.
String sanitizeUserContent(String text, {int maxLength = 2000}) {
  var result = text.trim();
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
