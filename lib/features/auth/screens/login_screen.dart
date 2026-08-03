import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_elevation.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/firestore_error_utils.dart';
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
          message: FirestoreErrorUtils.userMessage(e),
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final authState = ref.watch(authProvider);
    final tokens = context.tokens;
    final maxWidth = isMobile ? double.infinity : 440.0;

    return Scaffold(
      backgroundColor: AppTheme.surfaceMuted,
      body: PremiumAuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.xxl : AppSpacing.section,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInSection(
                      delayMs: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLight,
                                ],
                              ),
                              boxShadow: AppElevation.soft(AppTheme.primaryDark),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'College Reality',
                            style: AppTypography.label('College Reality').copyWith(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Welcome Back',
                            style: AppTypography.display('Welcome Back').copyWith(
                              fontSize: isMobile ? 28 : 32,
                              color: tokens.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Sign in to continue to College Reality',
                            style: AppTypography.body(
                              'Sign in to continue to College Reality',
                            ).copyWith(color: tokens.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
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
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Flexible(
                                          child: Text(
                                            'Remember me',
                                            style: AppTypography.caption(
                                              'Remember me',
                                            ).copyWith(
                                              color: tokens.textPrimary,
                                              fontWeight: FontWeight.w600,
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
                      child: _PremiumSignInButton(
                        isLoading: authState.isLoading,
                        onPressed: _handleEmailLogin,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FadeInSection(
                      delayMs: 180,
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: tokens.borderSubtle)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'OR',
                              style: AppTypography.overline('OR').copyWith(
                                color: tokens.textTertiary,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: tokens.borderSubtle)),
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
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.body(
                              "Don't have an account? ",
                            ).copyWith(color: tokens.textSecondary),
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
                                  style: AppTypography.caption(
                                    authState.error ?? '',
                                  ).copyWith(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _PremiumSignInButton extends StatelessWidget {
  const _PremiumSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          ),
          boxShadow: AppElevation.soft(AppTheme.primaryDark),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Sign In',
                      style: AppTypography.button('Sign In'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
