import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../../core/widgets/index.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';
import '../providers/super_admin_provider.dart';
import '../router/super_admin_route_names.dart';

class SuperAdminLoginScreen extends ConsumerStatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  ConsumerState<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends ConsumerState<SuperAdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      SnackBarHelper.showErrorSnackBar(context, message: 'Enter email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signInWithEmail(email, password);
      ref.invalidate(isSuperAdminProvider);
      ref.invalidate(currentUserDetailProvider);

      final isSuperAdmin = await ref.read(isSuperAdminProvider.future);
      if (!mounted) return;

      if (isSuperAdmin) {
        context.go(SuperAdminRouteNames.dashboard);
      } else {
        await ref.read(authServiceProvider).signOut();
        if (!mounted) return;
        context.go(SuperAdminRouteNames.accessDenied);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: 'Login failed: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF312E81), Color(0xFF6366F1)],
                  ),
                ),
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 64, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(height: 24),
                    Text(
                      'College Reality',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Super Admin Web Panel\nDesktop-first platform management.',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isWide) ...[
                        Icon(Icons.admin_panel_settings, size: 48, color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Super Admin Sign In',
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Restricted to super_admin accounts only.',
                        style: GoogleFonts.inter(color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _signIn,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryDark,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
