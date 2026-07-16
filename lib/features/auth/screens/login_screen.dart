import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../../../core/widgets/index.dart';
import '../../../core/services/preferences_service.dart';
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

    return Scaffold(
      body: PremiumAuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 20),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to College Reality',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 40),

                // Form
                Form(
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
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: true,
                        validator: ValidationUtil.validateRequired,
                        prefixIcon: Icons.lock_outline,
                        isRequired: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          'Remember me',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextLink(
                      text: 'Forgot password?',
                      fontSize: 13,
                      onPressed: () => context.go(RouteNames.forgotPassword),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login Button
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: authState.isLoading,
                  onPressed: _handleEmailLogin,
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray400,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In
                GoogleSignInButton(
                  isLoading: authState.isLoading,
                  onPressed: _handleGoogleLogin,
                ),

                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray600,
                      ),
                    ),
                    TextLink(
                      text: 'Sign Up',
                      fontSize: 14,
                      onPressed: () => context.go(RouteNames.signup),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Error message if login failed
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.errorColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.errorColor,
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
}
