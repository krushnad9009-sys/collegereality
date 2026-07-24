import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/index.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../../colleges/providers/college_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/google_auth_helper.dart';
import '../utils/validation_util.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _emailLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedEmail());
  }

  Future<void> _loadSavedEmail() async {
    if (_emailLoaded) return;
    _emailLoaded = true;
    final prefs = ref.read(preferencesServiceProvider);
    final rememberMe = await prefs.getRememberMe();
    final savedEmail = await prefs.getSavedEmail();
    if (rememberMe && savedEmail != null && mounted) {
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final prefs = ref.read(preferencesServiceProvider);
      await prefs.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await prefs.saveEmail(_emailController.text.trim());
      } else {
        await prefs.clearSavedEmail();
      }

      if (mounted) {
        ref.invalidate(collegeSeedProvider);
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Logged in successfully!',
        );
        context.go(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signInWithGoogle();

      final authState = ref.read(authProvider);
      if (authState.error != null || authState.user == null) {
        if (mounted && authState.error != null) {
          SnackBarHelper.showInfoSnackBar(
            context,
            message: authState.error!,
          );
        }
        return;
      }

      await syncGoogleUserToFirestore(ref, authState.user!);

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Logged in with Google!',
        );
        context.go(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Google login failed. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: PremiumAuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.pageH : AppSpacing.section + 8,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInSection(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Welcome Back',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sign in to continue to College Reality',
                          style: textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section + 8),

                  FadeInSection(
                    delayMs: 80,
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      radius: tokens.cardRadius,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              label: 'Email Address',
                              hint: 'Enter your email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: ValidationUtil.validateEmail,
                              prefixIcon: Icons.email_outlined,
                              isRequired: true,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              obscureText: true,
                              validator: ValidationUtil.validateRequired,
                              prefixIcon: Icons.lock_outline,
                              isRequired: true,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(
                                            () => _rememberMe = value ?? false,
                                          );
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Flexible(
                                        child: Text(
                                          'Remember me',
                                          style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextLink(
                                  text: 'Forgot password?',
                                  fontSize: 13,
                                  onPressed: () =>
                                      context.go(RouteNames.forgotPassword),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.section),

                  FadeInSection(
                    delayMs: 140,
                    child: PrimaryButton(
                      label: 'Sign In',
                      isLoading: authState.isLoading,
                      onPressed: _handleEmailLogin,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  FadeInSection(
                    delayMs: 180,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(color: tokens.borderSubtle),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'OR',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tokens.textTertiary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: tokens.borderSubtle),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  FadeInSection(
                    delayMs: 220,
                    child: GoogleSignInButton(
                      isLoading: authState.isLoading,
                      onPressed: _handleGoogleLogin,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.section),

                  FadeInSection(
                    delayMs: 260,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                        TextLink(
                          text: 'Sign Up',
                          fontSize: 14,
                          onPressed: () => context.go(RouteNames.signup),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  if (authState.error != null)
                    FadeInSection(
                      delayMs: 300,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 0.4),
                          ),
                          borderRadius:
                              BorderRadius.circular(tokens.buttonRadius),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                authState.error ?? '',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
