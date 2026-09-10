/// Helpers for keeping personal data out of logs and crash reports.
///
/// Every diagnostic line that would otherwise interpolate an email address
/// or a phone number should pass it through one of these first. They keep
/// just enough of the value to correlate log lines during debugging
/// (first char of the local part, last 2 digits of the number) while never
/// emitting the whole identifier.
library;

/// `krushna@example.com` -> `k***@e***`. `null`/empty -> `(none)`.
String redactEmail(String? email) {
  if (email == null || email.isEmpty) return '(none)';
  final at = email.indexOf('@');
  if (at <= 0) return '***';
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  final localHint = local.isNotEmpty ? local[0] : '';
  final domainHint = domain.isNotEmpty ? domain[0] : '';
  return '$localHint***@$domainHint***';
}

/// `+919876543210` -> `+91******3210` (last 4 kept). `null`/empty -> `(none)`.
String redactPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '(none)';
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '****';
  final last4 = digits.substring(digits.length - 4);
  final prefix = phone.startsWith('+') ? '+' : '';
  return '$prefix${'*' * (digits.length - 4)}$last4';
}
