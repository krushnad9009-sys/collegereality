import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/route_names.dart';
import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_theme.dart';
import '../widgets/index.dart';
import 'device_security_provider.dart';
import 'device_security_service.dart';

/// Terminal screen shown instead of the app when
/// [DeviceSecurityService] flags root/jailbreak or Android Developer
/// Options/USB debugging (release builds only). The router
/// (app_router.dart) redirects every other route here while blocked, and
/// away from here the instant a "Retry" finds the device clean again --
/// see `_resolveRedirect`.
class SecurityBlockScreen extends ConsumerStatefulWidget {
  const SecurityBlockScreen({super.key});

  @override
  ConsumerState<SecurityBlockScreen> createState() =>
      _SecurityBlockScreenState();
}

class _SecurityBlockScreenState extends ConsumerState<SecurityBlockScreen> {
  bool _checking = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> _openDeveloperSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SecurityBlockScreen] could not open settings: $e');
      }
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not open Settings. Please open it manually: '
              'Settings → System → Developer options.',
        );
      }
    }
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      final status = await DeviceSecurityService.recheck();
      // Keep the router's own cached read in sync with the fresh result,
      // so a subsequent redirect elsewhere in the app doesn't immediately
      // re-evaluate a stale "blocked" value.
      ref.invalidate(deviceSecurityStatusProvider);
      if (!mounted) return;
      if (status.isBlocked) {
        SnackBarHelper.showInfoSnackBar(
          context,
          message: 'Still detected. Please disable it and try again.',
        );
      } else {
        context.go(RouteNames.home);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final statusAsync = ref.watch(deviceSecurityStatusProvider);
    final status = statusAsync.valueOrNull;
    final rooted = status?.isRooted ?? false;

    final String message;
    if (rooted && !(status?.isDeveloperModeEnabled ?? false)) {
      message = 'Security Restriction: This device appears to be rooted or '
          'jailbroken. College Reality cannot run on a modified device to '
          'protect your account and data.';
    } else {
      message = 'Security Restriction: Developer Mode / USB Debugging is '
          'turned ON. Please disable Developer Options in your Android '
          'settings to continue using College Reality.';
    }

    return PopScope(
      // A user can't back out of this screen -- there is nothing safe to
      // go back to while the device is flagged.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gpp_bad_rounded,
                        size: 42,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Access Restricted',
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakarta(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakarta(
                        fontSize: 14.5,
                        height: 1.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (_isAndroid) ...[
                      PrimaryButton(
                        label: 'Open Developer Settings',
                        onPressed: _openDeveloperSettings,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _checking ? null : _retry,
                        icon: _checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          _checking ? 'Checking…' : 'Retry / Refresh Status',
                          style: AppFonts.plusJakarta(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
