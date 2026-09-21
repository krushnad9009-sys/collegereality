import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/sign_out.dart';
import '../../legal/screens/legal_screens.dart';
import '../services/onboarding_location_resolver.dart';
import '../services/onboarding_permission_service.dart';

enum _Permission { photos, location, notifications }

/// Per-tile state: a switch while [pending], then the outcome of the request.
enum _PermissionState { pending, requesting, granted, denied }

/// How long saving may take before we stop waiting and let the user retry.
/// Bounded because on web a Firestore write never resolves while offline.
const Duration _kSaveTimeout = Duration(seconds: 15);

/// The ONE post-login onboarding step: the full Terms & Conditions, the three
/// optional permissions (gallery, location, notifications) and a single
/// "I Accept Terms & Grant Permissions" action. The router
/// (`onboardingGateRedirect`) shows it until `UserModel.hasCompletedOnboarding`
/// is true, then sends the user straight to Home.
///
/// Two different rules live on this one screen, on purpose:
///  * Terms are a hard gate. If saving the acceptance fails the user stays
///    here and can retry; the back gesture is blocked (sign out is the only
///    way out).
///  * Permissions never block. Granting, denying or switching any of them off
///    is always a valid, complete answer.
///
/// Accounts that accepted the Terms under the earlier two-screen flow but
/// never answered the permissions only see the permissions half, so their
/// original `termsAcceptedAt` is never overwritten.
class PermissionsTermsScreen extends ConsumerStatefulWidget {
  const PermissionsTermsScreen({super.key});

  @override
  ConsumerState<PermissionsTermsScreen> createState() =>
      _PermissionsTermsScreenState();
}

class _PermissionsTermsScreenState
    extends ConsumerState<PermissionsTermsScreen> {
  final _termsController = ScrollController();

  // Snapshotted once: the user doc refreshes right after saving, and the
  // layout must not flip underneath the navigation to Home.
  late final bool _needsTerms;
  late final bool _needsPermissions;

  final _enabled = <_Permission, bool>{
    for (final p in _Permission.values) p: true,
  };
  final _states = <_Permission, _PermissionState>{
    for (final p in _Permission.values) p: _PermissionState.pending,
  };

  // Kept so a retry after a failed save doesn't resolve location again.
  OnboardingLocationResult? _locationResult;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    // Unknown user doc (still loading / failed to load) => owe both halves,
    // which is the right answer for a brand-new account.
    _needsTerms = !(user?.hasAcceptedTerms ?? false);
    _needsPermissions = !(user?.hasCompletedPermissionsOnboarding ?? false);
  }

  @override
  void dispose() {
    _termsController.dispose();
    super.dispose();
  }

  bool _shouldRequest(_Permission p) =>
      _enabled[p]! && _states[p] == _PermissionState.pending;

  bool get _anyPermissionSelected =>
      _Permission.values.any((p) => _shouldRequest(p));

  void _setState(_Permission p, _PermissionState state) {
    if (!mounted) return;
    setState(() => _states[p] = state);
  }

  /// Requests every selected permission, one after another. Sequential, not
  /// parallel: on iOS, two native permission dialogs shown back-to-back
  /// without awaiting can silently drop the second.
  Future<void> _requestSelectedPermissions() async {
    final service = ref.read(onboardingPermissionServiceProvider);

    if (_shouldRequest(_Permission.photos)) {
      _setState(_Permission.photos, _PermissionState.requesting);
      final granted = await service.requestPhotos();
      _setState(
        _Permission.photos,
        granted ? _PermissionState.granted : _PermissionState.denied,
      );
    }

    if (_shouldRequest(_Permission.location)) {
      _setState(_Permission.location, _PermissionState.requesting);
      final result = await service.requestLocation();
      _locationResult = result;
      _setState(
        _Permission.location,
        result.granted ? _PermissionState.granted : _PermissionState.denied,
      );
    }

    if (_shouldRequest(_Permission.notifications)) {
      _setState(_Permission.notifications, _PermissionState.requesting);
      final granted = await service.requestNotifications();
      _setState(
        _Permission.notifications,
        granted ? _PermissionState.granted : _PermissionState.denied,
      );
    }
  }

  Future<void> _acceptAndContinue() async {
    if (_isProcessing) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      await signOutAndRedirect(context, ref);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (_needsPermissions) await _requestSelectedPermissions();

      final location = _locationResult ?? OnboardingLocationResult.notProvided;
      await ref
          .read(userRepositoryProvider)
          .completeOnboarding(
            uid,
            recordTerms: _needsTerms,
            recordPermissions: _needsPermissions,
            state: location.state,
            city: location.city,
            locationGranted: location.granted,
          )
          .timeout(_kSaveTimeout);
    } catch (e, st) {
      // Not saved => the Terms are NOT recorded, so stay put and let the user
      // retry (permissions already answered are not asked again).
      CrashlyticsService.recordError(e, st, reason: 'PermissionsTerms (save)');
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showErrorSnackBar(
          context,
          message: e is TimeoutException
              ? 'Saving is taking too long. Check your connection and try again.'
              : FirestoreErrorUtils.userMessage(e),
        );
      }
      return;
    }

    // Saved. Refreshing the cached user doc is best-effort: the router only
    // needs it to see the completed flags, and if it can't load it lets the
    // user through rather than trapping them.
    ref.invalidate(currentUserDetailProvider);
    try {
      await ref
          .read(currentUserDetailProvider.future)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (mounted) context.go(RouteNames.home);
  }

  String get _title {
    if (_needsTerms && _needsPermissions) return 'Welcome to College Reality';
    if (_needsTerms) return 'Terms & Conditions';
    return 'Set Up Your Experience';
  }

  String get _subtitle {
    if (_needsTerms && _needsPermissions) {
      return 'One quick step: read our Terms & Conditions and choose the '
          'permissions you want to enable.';
    }
    if (_needsTerms) {
      return 'Please read and accept our Terms & Conditions to start using '
          'College Reality.';
    }
    return 'A few optional permissions to get the most out of College '
        'Reality. You can change these later in your device settings.';
  }

  String get _buttonLabel {
    if (!_needsTerms) return 'Continue';
    if (_needsPermissions && _anyPermissionSelected) {
      return 'I Accept Terms & Grant Permissions';
    }
    return 'I Accept Terms';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      // Hard gate: the back gesture must not escape it. Sign out is the exit.
      canPop: false,
      child: Scaffold(
        backgroundColor: tokens.surfaceMuted,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                children: [
                  // Everything scrolls except the action bar, so the button is
                  // always reachable on short phones / small browser windows.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final termsHeight = (constraints.maxHeight * 0.42)
                            .clamp(240.0, 420.0);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageH,
                            AppSpacing.xl,
                            AppSpacing.pageH,
                            AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(
                                icon: Icons.verified_user_outlined,
                                title: _title,
                                subtitle: _subtitle,
                                color: primary,
                              ),
                              if (_needsTerms) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _TermsCard(
                                  controller: _termsController,
                                  height: termsHeight,
                                ),
                              ],
                              if (_needsPermissions) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _SectionLabel('Permissions (optional)'),
                                const SizedBox(height: AppSpacing.sm),
                                for (final p in _Permission.values) ...[
                                  _PermissionTile(
                                    icon: _iconFor(p),
                                    title: _titleFor(p),
                                    description: _descriptionFor(p),
                                    enabled: _enabled[p]!,
                                    state: _states[p]!,
                                    locked: _isProcessing,
                                    onChanged: (v) =>
                                        setState(() => _enabled[p] = v),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageH,
                      AppSpacing.sm,
                      AppSpacing.pageH,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_needsPermissions)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              'Permissions are optional — switch off any you '
                              'would rather skip.',
                              textAlign: TextAlign.center,
                              style: AppFonts.plusJakarta(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: tokens.textTertiary,
                              ),
                            ),
                          ),
                        PrimaryButton(
                          label: _buttonLabel,
                          isLoading: _isProcessing,
                          onPressed: _isProcessing ? null : _acceptAndContinue,
                        ),
                        TextButton(
                          onPressed: _isProcessing
                              ? null
                              : () => signOutAndRedirect(context, ref),
                          child: Text(
                            'Not now, sign out',
                            style: AppFonts.plusJakarta(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tokens.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(_Permission p) => switch (p) {
    _Permission.photos => Icons.photo_library_outlined,
    _Permission.location => Icons.location_on_outlined,
    _Permission.notifications => Icons.notifications_outlined,
  };

  static String _titleFor(_Permission p) => switch (p) {
    _Permission.photos => 'Gallery / Photos',
    _Permission.location => 'Location',
    _Permission.notifications => 'Notifications',
  };

  static String _descriptionFor(_Permission p) => switch (p) {
    _Permission.photos =>
      'To upload a profile picture, college photos & documents',
    _Permission.location =>
      'To detect your state and city for localized college content',
    _Permission.notifications =>
      'For review updates, admin announcements & alerts',
  };
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppFonts.plusJakarta(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppFonts.plusJakarta(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.plusJakarta(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: context.tokens.textSecondary,
      ),
    );
  }
}

/// The complete Terms & Conditions, inline and scrollable -- the same
/// canonical copy the read-only `/terms-of-service` screen shows.
class _TermsCard extends StatelessWidget {
  final ScrollController controller;
  final double height;

  const _TermsCard({required this.controller, required this.height});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      key: const ValueKey('terms-card'),
      height: height,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          children: [
            Text(
              termsAndConditionsIntro,
              style: AppFonts.plusJakarta(
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final section in termsOfServiceSections) ...[
              Text(
                section.heading,
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.body,
                style: AppFonts.plusJakarta(
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

/// One permission: tap anywhere on the tile to switch it on/off; once it has
/// been requested the switch is replaced by the outcome.
class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final _PermissionState state;
  final bool locked;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.state,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final interactive = state == _PermissionState.pending && !locked;

    return Material(
      color: tokens.surfaceElevated,
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        onTap: interactive ? () => onChanged(!enabled) : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              _trailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing() {
    switch (state) {
      case _PermissionState.pending:
        return Switch(
          key: ValueKey('permission-switch-$title'),
          value: enabled,
          onChanged: locked ? null : onChanged,
        );
      case _PermissionState.requesting:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _PermissionState.granted:
        return const Icon(Icons.check_circle, color: Colors.green, size: 22);
      case _PermissionState.denied:
        return Icon(
          Icons.cancel_outlined,
          color: Colors.grey.shade400,
          size: 22,
        );
    }
  }
}
