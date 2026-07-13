import '../../../core/constants/communication_constants.dart';

/// Basic offensive terms filter — extend via remote config in production.
const List<String> _offensiveTerms = [
  'abuse',
  'hate',
  'kill',
  'scam',
  'fraud',
  'idiot',
  'stupid',
  'bastard',
];

/// Detects likely spam patterns in user-generated text.
bool isLikelySpam(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return true;
  if (trimmed.length < 2) return true;

  final lower = trimmed.toLowerCase();
  final linkCount = RegExp(r'https?://|www\.').allMatches(lower).length;
  if (linkCount >= 3) return true;

  final repeated = RegExp(r'(.)\1{6,}');
  if (repeated.hasMatch(trimmed)) return true;

  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length >= 4) {
    final unique = words.map((w) => w.toLowerCase()).toSet();
    if (unique.length == 1) return true;
  }

  final alpha = trimmed.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (alpha.isNotEmpty) {
    final capsCount = alpha
        .split('')
        .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
        .length;
    final capsRatio = capsCount / alpha.length;
    if (trimmed.length > 20 && capsRatio > 0.8) return true;
  }

  return false;
}

/// Returns true when text contains offensive terms.
bool containsOffensiveContent(String text) {
  final lower = text.toLowerCase();
  for (final term in _offensiveTerms) {
    if (RegExp(r'\b' + RegExp.escape(term) + r'\b').hasMatch(lower)) {
      return true;
    }
  }
  return false;
}

/// Combined moderation check — spam or offensive.
ModerationResult moderateContent(String text) {
  if (isLikelySpam(text)) {
    return const ModerationResult(
      allowed: false,
      reason: 'spam',
    );
  }
  if (containsOffensiveContent(text)) {
    return const ModerationResult(
      allowed: false,
      reason: 'offensive',
    );
  }
  return const ModerationResult(allowed: true);
}

/// Whether report count has reached auto-hide threshold.
bool shouldAutoHide(int reportCount) {
  return reportCount >= CommunicationConstants.spamReportThreshold;
}

class ModerationResult {
  final bool allowed;
  final String reason;

  const ModerationResult({
    required this.allowed,
    this.reason = '',
  });
}
