import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/google_auth_helper.dart';
import '../utils/validation_util.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'Please agree to the Terms & Conditions',
      );
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final firebaseUser = ref.read(authProvider).user;
      if (firebaseUser == null) {
        throw Exception('Failed to get user data');
      }

      final realName = _nameController.text.trim();
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: realName,
        verifiedRealName: realName,
        userType: 'student',
        isVerified: false,
        isEmailVerified: firebaseUser.emailVerified,
        displayNameSetupComplete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.createUser(userModel);
      await ref.read(authServiceProvider).sendEmailVerification();

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message:
              'Account created! Please verify your email from your inbox.',
        );
        context.go(RouteNames.displayNameSetup);
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

  Future<void> _handleGoogleSignup() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signInWithGoogle();

      final authState = ref.read(authProvider);
      if (authState.error != null || authState.user == null) {
        if (mounted && authState.error != null) {
          SnackBarHelper.showInfoSnackBar(context, message: authState.error!);
        }
        return;
      }

      await syncGoogleUserToFirestore(ref, authState.user!);

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Signed up with Google!',
        );
        final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
        if (userDetail != null && !userDetail.displayNameSetupComplete) {
          context.go(RouteNames.displayNameSetup);
        } else {
          context.go(RouteNames.home);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Google sign-up failed. Please try again.',
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius:
                            BorderRadius.circular(tokens.buttonRadius),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: tokens.surfaceMuted,
                            borderRadius:
                                BorderRadius.circular(tokens.buttonRadius),
                            border: Border.all(color: tokens.borderSubtle),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  FadeInSection(
                    delayMs: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Join India\'s largest college review platform',
                          style: textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),

                  FadeInSection(
                    delayMs: 100,
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      radius: tokens.cardRadius,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              validator: ValidationUtil.validateDisplayName,
                              prefixIcon: Icons.person_outline,
                              isRequired: true,
                            ),
                            const SizedBox(height: AppSpacing.xl),
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
                              hint: 'Create a strong password',
                              controller: _passwordController,
                              obscureText: true,
                              validator: ValidationUtil.validatePassword,
                              prefixIcon: Icons.lock_outline,
                              isRequired: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Must contain uppercase, lowercase, numbers, and be at least 8 characters',
                                style: textTheme.bodySmall?.copyWith(
                                  color: tokens.textTertiary,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            CustomTextField(
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              controller: _confirmPasswordController,
                              obscureText: true,
                              validator: (value) =>
                                  ValidationUtil.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                              prefixIcon: Icons.lock_outline,
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  FadeInSection(
                    delayMs: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() => _agreeToTerms = value ?? false);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: RichText(
                              text: TextSpan(
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textSecondary,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push(
                                            RouteNames.termsOfService,
                                          ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push(
                                            RouteNames.privacyPolicy,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  FadeInSection(
                    delayMs: 200,
                    child: PrimaryButton(
                      label: 'Create Account',
                      isLoading: authState.isLoading,
                      onPressed: _handleSignup,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  FadeInSection(
                    delayMs: 240,
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
                    delayMs: 280,
                    child: GoogleSignInButton(
                      isLoading: authState.isLoading,
                      onPressed: _handleGoogleSignup,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  FadeInSection(
                    delayMs: 320,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                        TextLink(
                          text: 'Sign In',
                          fontSize: 14,
                          onPressed: () => context.go(RouteNames.login),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  if (authState.error != null)
                    FadeInSection(
                      delayMs: 360,
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
