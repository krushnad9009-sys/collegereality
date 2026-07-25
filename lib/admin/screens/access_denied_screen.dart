import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../router/super_admin_route_names.dart';

class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_outlined, size: 56, color: AppTheme.errorColor),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'This panel is restricted to super administrators. '
                  'Admin, moderator, and student accounts cannot access this console.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.gray600, height: 1.5),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go(SuperAdminRouteNames.login);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out and return to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
