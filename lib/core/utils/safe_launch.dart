import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// True only for absolute http(s) URLs with a host. Links stored in
/// user-written documents (post PDFs, certificates, review videos) must
/// never open `intent:`, `javascript:`, `file:` or app-specific schemes.
bool isSafeWebUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

/// Opens a user-supplied web link in an external app/browser. Returns false
/// (and opens nothing) for anything that isn't a plain http(s) URL.
Future<bool> launchSafeWebUrl(String raw) async {
  if (!isSafeWebUrl(raw)) {
    debugPrint('[SafeLaunch] blocked non-web URL');
    return false;
  }
  try {
    return await launchUrl(
      Uri.parse(raw.trim()),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('[SafeLaunch] $e');
    return false;
  }
}
