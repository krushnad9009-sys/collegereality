import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../services/onboarding_location_resolver.dart';

/// Per-card state shown next to each permission row.
enum _PermissionState { pending, requesting, granted, denied }

/// One-time post-login onboarding: gallery/location/notification
/// permissions. The router's redirect gate (`app_router.dart`) shows this
/// exactly once per account, after the Terms gate and display-name setup
/// (if needed), immediately before the user first reaches Home -- see
/// `UserModel.hasCompletedPermissionsOnboarding`.
///
/// Unlike [TermsGateScreen] (a genuinely blocking gate), this screen must
/// NEVER block the user from reaching Home: denying or skipping any/all of
/// the three permissions below is always a valid, complete outcome.
class PermissionsOnboardingScreen extends ConsumerStatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  ConsumerState<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends ConsumerState<PermissionsOnboardingScreen> {
  bool _isProcessing = false;
  // Set once _finish starts, so a slow Allow All and a Skip tap can never
  // both save and navigate.
  bool _finished = false;
  _PermissionState _photos = _PermissionState.pending;
  _PermissionState _location = _PermissionState.pending;
  _PermissionState _notifications = _PermissionState.pending;

  Future<void> _requestPhotos() async {
    if (!mounted) return;
    setState(() => _photos = _PermissionState.requesting);
    try {
      // Flutter Web's file picker is a plain <input type=file> -- there is
      // no OS-level "photo library" permission concept to request there.
      if (kIsWeb) {
        setState(() => _photos = _PermissionState.granted);
        return;
      }
      final status = await Permission.photos.request();
      if (!mounted) return;
      setState(() {
        _photos = status.isGranted || status.isLimited
            ? _PermissionState.granted
            : _PermissionState.denied;
      });
    } catch (e, st) {
      CrashlyticsService.recordError(e, st, reason: 'PermissionsOnboarding (photos)');
      if (mounted) setState(() => _photos = _PermissionState.denied);
    }
  }

  Future<void> _requestNotifications() async {
    if (!mounted) return;
    setState(() => _notifications = _PermissionState.requesting);
    try {
      // Mirrors FirebaseMessagingService.initialize(), which also only
      // requests this on non-web -- web push isn't wired up in this app.
      if (kIsWeb) {
        setState(() => _notifications = _PermissionState.denied);
        return;
      }
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!mounted) return;
      setState(() {
        _notifications =
            granted ? _PermissionState.granted : _PermissionState.denied;
      });
    } catch (e, st) {
      CrashlyticsService.recordError(
        e,
        st,
        reason: 'PermissionsOnboarding (notifications)',
      );
      if (mounted) setState(() => _notifications = _PermissionState.denied);
    }
  }

  Future<OnboardingLocationResult> _requestLocation() async {
    if (mounted) setState(() => _location = _PermissionState.requesting);
    // Never throws and never hangs -- every failure or timeout degrades to
    // "Not Provided" so the spinner below always stops.
    final result = await resolveOnboardingLocation();
    if (mounted) {
      setState(() {
        _location =
            result.granted ? _PermissionState.granted : _PermissionState.denied;
      });
    }
    return result;
  }

  Future<void> _allowAll() async {
    if (_isProcessing || _finished) return;
    setState(() => _isProcessing = true);
    var locationResult = OnboardingLocationResult.notProvided;
    try {
      // Sequential, not parallel: on iOS, showing two native permission
      // dialogs back-to-back without waiting can silently drop the second.
      await _requestPhotos();
      locationResult = await _requestLocation();
      await _requestNotifications();
    } catch (e, st) {
      // Each step already catches its own errors; this is the backstop so
      // an unexpected throw can never leave the spinner running.
      CrashlyticsService.recordError(
        e,
        st,
        reason: 'PermissionsOnboarding (allow all)',
      );
    }
    await _finish(locationResult);
  }

  Future<void> _skip() => _finish(OnboardingLocationResult.notProvided);

  Future<void> _finish(OnboardingLocationResult locationResult) async {
    if (_finished) return;
    setState(() {
      _finished = true;
      _isProcessing = true;
    });
    final uid = ref.read(currentUserProvider)?.uid;
    try {
      if (uid != null) {
        // Bounded: on web a Firestore write doesn't resolve while offline,
        // which would otherwise leave the spinner running forever.
        await () async {
          await ref.read(userRepositoryProvider).completePermissionsOnboarding(
                uid,
                state: locationResult.state,
                city: locationResult.city,
                locationGranted: locationResult.granted,
              );
          ref.invalidate(currentUserDetailProvider);
          // Wait for the refreshed doc so the router's redirect sees
          // hasCompletedPermissionsOnboarding: true on the very next
          // navigation -- same pattern as TermsGateScreen.
          await ref.read(currentUserDetailProvider.future);
        }()
            .timeout(const Duration(seconds: 10));
      }
    } catch (e, st) {
      CrashlyticsService.recordError(
        e,
        st,
        reason: 'PermissionsOnboarding (save)',
      );
      // Deliberately NOT re-throwing or staying on screen: this gate must
      // never block reaching Home, even if persisting the choice failed.
      // (A failed save does mean the router may show this screen again on
      // the next cold start/navigation, since hasCompletedPermissionsOnboarding
      // stayed false -- an acceptable, rare degradation next to actually
      // trapping the user.)
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: "Couldn't save your preferences, but you're all set.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        context.go(RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      // Not a hard gate like TermsGateScreen -- but there's nowhere
      // meaningful to pop back to (this sits between login and Home), so
      // route the back gesture through the same "skip" outcome instead of
      // leaving it a no-op.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _skip();
      },
      child: Scaffold(
        backgroundColor: tokens.surfaceMuted,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageH,
                    AppSpacing.xl,
                    AppSpacing.pageH,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppReveal(
                        delayMs: 0,
                        slideFrom: 0.12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Set Up Your Experience',
                              style: AppFonts.plusJakarta(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              "A few optional permissions to get the most out of "
                              "College Reality. You can always change these "
                              "later in Settings.",
                              style: AppFonts.plusJakarta(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppReveal(
                        delayMs: 100,
                        child: _PermissionCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Gallery / Photos Access',
                          description:
                              'To upload a profile picture, college photos & documents',
                          state: _photos,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppReveal(
                        delayMs: 160,
                        child: _PermissionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Location Access',
                          description:
                              'To detect your state and city for localized college content',
                          state: _location,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppReveal(
                        delayMs: 220,
                        child: _PermissionCard(
                          icon: Icons.notifications_outlined,
                          title: 'Notification Access',
                          description:
                              'For review updates, admin announcements & alerts',
                          state: _notifications,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppReveal(
                delayMs: 280,
                slideFrom: 0.15,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageH,
                    AppSpacing.md,
                    AppSpacing.pageH,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Allow All',
                        isLoading: _isProcessing,
                        onPressed: _isProcessing ? null : _allowAll,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SecondaryButton(
                        label: 'Skip for Now',
                        isLoading: false,
                        onPressed: _finished ? null : _skip,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final _PermissionState state;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.plusJakarta(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppFonts.plusJakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusIndicator(state: state),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final _PermissionState state;

  const _StatusIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _PermissionState.pending:
        return const SizedBox(width: 20, height: 20);
      case _PermissionState.requesting:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _PermissionState.granted:
        return const Icon(Icons.check_circle, color: Colors.green, size: 22);
      case _PermissionState.denied:
        return Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 22);
    }
  }
}
