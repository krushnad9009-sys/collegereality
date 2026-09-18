import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/widgets/index.dart';
import '../models/admin_models.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_shell_layout.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  // Two independent data modes, mirroring AdminCollegesScreen:
  //  * no filter text -> paginated listing of ALL users (this list + cursor)
  //  * filter text present -> one-shot searchUsers() results (unpaginated,
  //    already capped at AdminConstants.maxSearchUsers -- unchanged)
  String? _cursor;
  bool _hasMore = false;
  List<AdminUserSearchResult> _users = [];
  bool _loading = false;
  String? _error;

  // null = All, true = Verified only, false = Unverified only.
  bool? _verifiedFilter;

  // Region analytics panel selection -- '' means "All" for either.
  String _regionState = '';
  String _regionCity = '';

  bool get _isFiltering => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        var results = await ref.read(adminUserSearchProvider(query).future);
        // searchUsers() has no server-side verified filter of its own (it's
        // already a small, bounded in-memory list, capped at
        // AdminConstants.maxSearchUsers) -- filter client-side instead of
        // adding one.
        if (_verifiedFilter != null) {
          results = results
              .where((u) =>
                  VerificationConstants.isApprovedStudentOrAlumni(
                    u.verificationBadge,
                    u.verificationStatus,
                  ) ==
                  _verifiedFilter)
              .toList();
        }
        if (!mounted) return;
        setState(() {
          _users = results;
          _cursor = null;
          _hasMore = false;
        });
        return;
      }

      final page = await ref.read(
        adminUserPageProvider(
          AdminUserPageParams(
            startAfterDocumentId: loadMore ? _cursor : null,
            verifiedFilter: _verifiedFilter,
          ),
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _users = loadMore ? [..._users, ...page.items] : page.items;
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Grant/Revoke Verified Badge. Two things this fixes vs. before:
  ///  1. The write is wrapped in try/catch with a visible error SnackBar --
  ///     previously a failed write (permission/network) threw uncaught out
  ///     of the button's onPressed, which Flutter just logs to console in
  ///     release builds. From the admin's side that read as "clicking the
  ///     button does nothing at all", indistinguishable from the button
  ///     being broken.
  ///  2. The badge flips in `_users` immediately on success, rather than
  ///     waiting on a full re-fetch from Firestore (_load()) to reflect
  ///     it -- true "instant", not just "fast".
  Future<void> _toggleVerified(AdminUserSearchResult user, bool nowVerified) async {
    try {
      await ref.read(adminUserModerationServiceProvider).setStudentVerified(
            user.uid,
            verified: nowVerified,
          );
      if (!mounted) return;
      setState(() {
        _users = [
          for (final u in _users)
            if (u.uid == user.uid)
              u.copyWith(
                verificationStatus: nowVerified
                    ? VerificationConstants.statusApproved
                    : VerificationConstants.statusRejected,
                verificationBadge: nowVerified
                    ? VerificationConstants.badgeVerifiedStudent
                    : VerificationConstants.badgeNone,
              )
            else
              u,
        ];
      });
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: nowVerified ? 'Verified badge granted' : 'Verified badge revoked',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Could not update verification: ${FirestoreErrorUtils.userMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isAdminUser = ref.watch(isAdminUserProvider).maybeWhen(data: (v) => v, orElse: () => false);

    return AdminShellLayout(
      title: 'User Management',
      isAdminUser: isAdminUser,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Search by name, email, mobile, or college (optional)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isFiltering
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _load();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: () => _load(), child: const Text('Search')),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<bool?>(
                value: _verifiedFilter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: true, child: Text('Verified Only')),
                  DropdownMenuItem(value: false, child: Text('Unverified Only')),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() => _verifiedFilter = value);
                        _load();
                      },
              ),
            ),
          ),
          _RegionAnalyticsPanel(
            state: _regionState,
            city: _regionCity,
            onStateChanged: (value) {
              setState(() {
                _regionState = value;
                _regionCity = ''; // city belongs to the previous state
              });
            },
            onCityChanged: (value) => setState(() => _regionCity = value),
          ),
          Expanded(
            child: _loading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          'Failed to load users: $_error',
                          style: AppFonts.plusJakarta(color: tokens.textSecondary),
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Text(
                              'No users found',
                              style: AppFonts.plusJakarta(color: tokens.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: _users.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              if (index == _users.length) {
                                return Center(
                                  child: _loading
                                      ? const Padding(
                                          padding: EdgeInsets.all(AppSpacing.sm),
                                          child: CircularProgressIndicator(),
                                        )
                                      : TextButton(
                                          onPressed: () => _load(loadMore: true),
                                          child: const Text('Load more'),
                                        ),
                                );
                              }
                              return _UserCard(
                                user: _users[index],
                                onChanged: () => _load(),
                                onToggleVerified: (nowVerified) =>
                                    _toggleVerified(_users[index], nowVerified),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AdminUserSearchResult user;
  final VoidCallback onChanged;
  final ValueChanged<bool> onToggleVerified;
  const _UserCard({
    required this.user,
    required this.onChanged,
    required this.onToggleVerified,
  });

  static bool _isRealValue(String? v) => v != null && v.isNotEmpty && v != 'Not Provided';

  /// Prefer the human-readable name; fall back to the raw ID only if the
  /// name is genuinely absent (not just empty).
  String? get _collegeLabel =>
      _isRealValue(user.collegeName) ? user.collegeName : (_isRealValue(user.collegeId) ? user.collegeId : null);

  bool get _hasContactDetails =>
      (user.phone?.isNotEmpty ?? false) || _collegeLabel != null || _cityState.isNotEmpty;

  /// 'City, State' when both are known/provided, just one when only that
  /// one is, or '' when neither is -- 'Not Provided' is the sentinel the
  /// permissions-onboarding screen writes when a user denies/skips
  /// location, filtered out here rather than displayed literally.
  String get _cityState {
    final parts = [user.city, user.state].where(_isRealValue).toList();
    return parts.join(', ');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user permanently?'),
        content: Text(
          'This will permanently delete ${user.email}. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminUserModerationServiceProvider).deleteUser(user.uid);
    onChanged();
  }

  Future<void> _warnUser(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue warning'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Warning message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send warning'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty) return;
    await ref.read(adminUserModerationServiceProvider).warnUser(user.uid, message: message);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(adminUserModerationServiceProvider);
    final status = user.accountStatus;
    final isVerified = VerificationConstants.isApprovedStudentOrAlumni(
      user.verificationBadge,
      user.verificationStatus,
    );

    Color statusColor;
    switch (status) {
      case AdminConstants.accountStatusBanned:
        statusColor = Colors.red;
      case AdminConstants.accountStatusSuspended:
        statusColor = Colors.orange;
      default:
        statusColor = Colors.green;
    }

    final tokens = context.tokens;
    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _UserAvatar(photoURL: user.photoURL, name: user.displayName ?? user.email),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email,
                      style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_hasContactDetails)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: 2,
                children: [
                  if (user.phone != null && user.phone!.isNotEmpty)
                    _DetailChip(icon: Icons.phone_outlined, text: user.phone!),
                  if (_collegeLabel != null)
                    _DetailChip(icon: Icons.school_outlined, text: _collegeLabel!),
                  if (_cityState.isNotEmpty)
                    _DetailChip(icon: Icons.location_on_outlined, text: _cityState),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusBadge(label: status, color: statusColor),
              const SizedBox(width: 6),
              isVerified
                  ? const StatusBadge(
                      label: 'Verified',
                      color: AppTheme.verifiedBlue,
                      icon: Icons.verified,
                    )
                  : StatusBadge(
                      label: 'Unverified',
                      color: Colors.grey.shade500,
                      icon: Icons.remove_circle_outline,
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
                ActionChip(
                  avatar: const Icon(Icons.warning_amber_outlined, size: 16),
                  label: const Text('Warn'),
                  onPressed: () => _warnUser(context, ref),
                ),
                if (status != AdminConstants.accountStatusSuspended)
                  ActionChip(
                    avatar: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Suspend'),
                    onPressed: () async {
                      await service.suspendUser(user.uid);
                      onChanged();
                    },
                  ),
                if (status != AdminConstants.accountStatusBanned)
                  ActionChip(
                    avatar: const Icon(Icons.block, size: 16),
                    label: const Text('Ban'),
                    onPressed: () async {
                      await service.banUser(user.uid);
                      onChanged();
                    },
                  ),
                if (status != AdminConstants.accountStatusActive)
                  ActionChip(
                    avatar: const Icon(Icons.restore, size: 16),
                    label: const Text('Restore'),
                    onPressed: () async {
                      await service.restoreAccount(user.uid);
                      onChanged();
                    },
                  ),
                ActionChip(
                  avatar: Icon(
                    isVerified ? Icons.remove_circle_outline : Icons.verified,
                    size: 16,
                    color: isVerified ? null : AppTheme.verifiedBlue,
                  ),
                  label: Text(
                    isVerified ? 'Revoke Verified Badge' : 'Grant Verified Badge',
                  ),
                  onPressed: () => onToggleVerified(!isVerified),
                ),
                ActionChip(
                  avatar: const Icon(Icons.delete_forever, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

/// Lightweight cached circular avatar for the user list -- decodes at the
/// display size (memCacheWidth/Height), not full resolution, and falls
/// back to initials on a missing photoURL or a failed/slow load rather
/// than leaving a blank circle or blocking the row on the image.
class _UserAvatar extends StatelessWidget {
  static const double _radius = 18;

  final String? photoURL;
  final String name;

  const _UserAvatar({required this.photoURL, required this.name});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final url = photoURL;
    if (url == null || url.isEmpty) {
      // Solid, non-muted background here (unlike the has-a-URL branch
      // below) since this is the only content in the circle -- white
      // initials need real contrast, not the page's muted surface tint.
      return CircleAvatar(radius: _radius, backgroundColor: AppTheme.primaryColor, child: _initials());
    }
    return CircleAvatar(
      radius: _radius,
      backgroundColor: tokens.surfaceMuted,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: _radius * 2,
          height: _radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (_radius * 2 * 2).round(),
          placeholder: (_, _) => _initials(),
          errorWidget: (_, _, _) => _initials(),
        ),
      ),
    );
  }

  Widget _initials() {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    return Text(initial, style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: Colors.white));
  }
}

/// Small icon+text pill for a user card's contact-detail row (mobile,
/// college, city/state) -- deliberately plainer than [StatusBadge] (no
/// tinted pill background) since these are informational, not statuses.
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tokens.textTertiary),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textSecondary),
        ),
      ],
    );
  }
}

/// State/City dropdown filters + Total/Active registered-student counts
/// for the selected region. State options come from the static
/// CollegeConstants.indianStates list (comprehensive regardless of
/// registration data); City options are loaded dynamically per selected
/// state from AdminUserModerationService.getCitiesForState -- the
/// distinct city values students in that state have actually registered
/// with, not a static gazetteer.
class _RegionAnalyticsPanel extends ConsumerWidget {
  final String state;
  final String city;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onCityChanged;

  const _RegionAnalyticsPanel({
    required this.state,
    required this.city,
    required this.onStateChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final citiesAsync = state.isEmpty
        ? const AsyncValue<List<String>>.data([])
        : ref.watch(adminCitiesForStateProvider(state));
    final statsAsync = ref.watch(
      adminRegionStudentStatsProvider((state: state, city: city)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Region Analytics',
            style: AppFonts.plusJakarta(fontWeight: FontWeight.w700, color: tokens.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: state,
                hint: const Text('All States'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All States')),
                  ...CollegeConstants.indianStates.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (value) => onStateChanged(value ?? ''),
              ),
              citiesAsync.when(
                loading: () => const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (cities) => DropdownButton<String>(
                  value: cities.contains(city) ? city : '',
                  hint: const Text('All Cities'),
                  underline: const SizedBox.shrink(),
                  // Disabled (not hidden) until a state is picked -- a
                  // city search only makes sense scoped to one state, and
                  // a disabled-but-visible control says why more clearly
                  // than the control just not being there yet.
                  onChanged: state.isEmpty
                      ? null
                      : (value) => onCityChanged(value ?? ''),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All Cities')),
                    ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(
              'Could not load region stats: $e',
              style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
            ),
            data: (stats) => Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.sm,
              children: [
                _StatPair(label: 'Total Registered', value: '${stats.total}'),
                _StatPair(
                  label: 'Active (online or last 7 days)',
                  value: stats.sampleCapped ? '~${stats.active}' : '${stats.active}',
                  hint: stats.sampleCapped
                      ? 'Based on the first ${stats.sampled} matching students'
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPair extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _StatPair({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppFonts.plusJakarta(fontSize: 22, fontWeight: FontWeight.w800, color: tokens.textPrimary),
        ),
        Text(label, style: AppFonts.plusJakarta(fontSize: 11.5, color: tokens.textSecondary)),
        if (hint != null)
          Text(hint!, style: AppFonts.plusJakarta(fontSize: 10, color: tokens.textTertiary)),
      ],
    );
  }
}


