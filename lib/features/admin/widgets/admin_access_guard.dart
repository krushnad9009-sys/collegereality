import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_fonts.dart';
import '../providers/admin_provider.dart';

/// Render-time RBAC gate for every `/admin/*` screen.
///
/// The GoRouter `redirect` in `config/router/app_router.dart` is the first
/// line of defence (it bounces non-staff away before an admin route is ever
/// built). This widget is the second, independent line: it re-verifies
/// [isStaffProvider] at build time so that a regression, race, or future
/// weakening of that single redirect can never expose admin content or
/// admin-only network calls to a student/guest. Firestore security rules
/// (`firestore.rules`) remain the authoritative third line for the data
/// itself — a non-staff user who somehow reached a screen still gets
/// permission-denied on every admin read/write.
///
/// Access here is granted to staff (moderator/admin/super_admin), matching
/// the router redirect and the `isStaff()` checks in `firestore.rules`.
/// Finer-grained admin-only vs moderator gating already happens inside the
/// individual screens (`AdminPermissions.can*`) and in the rules.
class AdminAccessGuard extends ConsumerWidget {
  final Widget child;

  const AdminAccessGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(isStaffProvider);

    return staffAsync.when(
      data: (isStaff) =>
          isStaff ? child : const _AdminAccessDenied(),
      // A failed role lookup is treated as "not staff" — never fail open.
      error: (_, _) => const _AdminAccessDenied(),
      loading: () => const _AdminAccessPending(),
    );
  }
}

class _AdminAccessPending extends StatelessWidget {
  const _AdminAccessPending();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Shown for a split second before the post-frame redirect fires, so a
/// non-staff user never sees admin UI even during that frame.
class _AdminAccessDenied extends StatefulWidget {
  const _AdminAccessDenied();

  @override
  State<_AdminAccessDenied> createState() => _AdminAccessDeniedState();
}

class _AdminAccessDeniedState extends State<_AdminAccessDenied> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Access denied',
                style: AppFonts.plusJakarta(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to view this area.',
                textAlign: TextAlign.center,
                style: AppFonts.plusJakarta(fontSize: 14),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
