import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/validation_util.dart';
import '../../colleges/providers/college_provider.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../communication/widgets/language_multi_select_field.dart';
import '../widgets/phone_verification_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  String? _selectedCollegeId;
  String? _selectedCollegeName;
  int? _batchYear;
  List<String> _languagesKnown = [];
  GuideCommunicationSettings _communicationSettings =
      const GuideCommunicationSettings();
  bool _isPhoneVerified = false;
  String? _verifiedPhone;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  void _populateFromUser(UserModel user) {
    _nameController.text = user.displayName ?? '';
    _courseController.text = user.course ?? '';
    _batchYear = user.batchYear;
    _selectedCollegeId = user.collegeId;
    _selectedCollegeName = user.collegeName;
    _languagesKnown = List<String>.from(user.languagesKnown);
    _communicationSettings = user.communicationSettings;
    _isPhoneVerified = user.isPhoneVerified;
    _verifiedPhone = user.phone;
  }

  Future<void> _saveProfile(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateUserProfile(
        displayName: _nameController.text.trim(),
      );

      await ref.read(userRepositoryProvider).updateUserProfile(
            uid: uid,
            displayName: _nameController.text.trim(),
            collegeId: _selectedCollegeId,
            collegeName: _selectedCollegeName,
            course: _courseController.text.trim().isEmpty
                ? null
                : _courseController.text.trim(),
            batchYear: _batchYear,
            languagesKnown: _languagesKnown,
            communicationSettings: _communicationSettings,
          );

      ref.invalidate(currentUserDetailProvider);

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Profile updated successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Verification email sent!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    }
  }

  Future<void> _checkVerification() async {
    final verified =
        await ref.read(authProvider.notifier).refreshEmailVerificationStatus();
    if (verified && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(userRepositoryProvider).verifyEmail(user.uid);
      }
      ref.invalidate(currentUserDetailProvider);
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Email verified successfully!',
        );
      }
    } else if (mounted) {
      SnackBarHelper.showInfoSnackBar(
        context,
        message: 'Email not verified yet. Check your inbox.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final userDetailAsync = ref.watch(currentUserDetailProvider);
    final collegesAsync = ref.watch(collegesProvider);

    if (authUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: userDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (userDetail) {
          if (userDetail != null &&
              _nameController.text.isEmpty &&
              userDetail.displayName != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _populateFromUser(userDetail));
              }
            });
          }

          final isEmailVerified = authUser.emailVerified;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        (_nameController.text.isNotEmpty
                                ? _nameController.text[0]
                                : authUser.email?[0] ?? 'S')
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      authUser.email ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isEmailVerified)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email not verified',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _sendVerificationEmail,
                                  child: const Text('Resend Email'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _checkVerification,
                                  child: const Text('I Verified'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_outlined,
                              color: AppTheme.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Email verified',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Your name',
                    controller: _nameController,
                    validator: ValidationUtil.validateDisplayName,
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  PhoneVerificationSection(
                    userId: authUser.uid,
                    currentPhone: _verifiedPhone ?? userDetail?.phone,
                    isPhoneVerified: _isPhoneVerified,
                    onVerified: (phone) {
                      setState(() {
                        _isPhoneVerified = true;
                        _verifiedPhone = phone;
                      });
                    },
                  ),
                  Text(
                    'College',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  collegesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('Could not load colleges'),
                    data: (colleges) {
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCollegeId,
                        decoration: InputDecoration(
                          hintText: 'Select your college',
                          filled: true,
                          fillColor: AppTheme.gray100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: colleges
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCollegeId = value;
                            _selectedCollegeName = colleges
                                .firstWhere((c) => c.id == value)
                                .name;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Course',
                    hint: 'e.g. B.Tech CSE',
                    controller: _courseController,
                    prefixIcon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(height: 16),
                  YearPickerField(
                    label: 'Batch Year',
                    value: _batchYear,
                    onChanged: (year) => setState(() => _batchYear = year),
                  ),
                  const SizedBox(height: 16),
                  LanguageMultiSelectField(
                    selected: _languagesKnown,
                    onChanged: (langs) =>
                        setState(() => _languagesKnown = langs),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Guide Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help students anonymously. Your phone and email stay private.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available as a guide'),
                    subtitle: Text(
                      userDetail?.anonymousGuideAlias ?? 'Guide #----',
                    ),
                    value: _communicationSettings.isGuideAvailable,
                    onChanged: (value) {
                      setState(() {
                        _communicationSettings = _communicationSettings
                            .copyWith(isGuideAvailable: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow video calls'),
                    value: _communicationSettings.videoCallsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _communicationSettings = _communicationSettings
                            .copyWith(videoCallsEnabled: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Camera on by default'),
                    value: _communicationSettings.cameraDefaultOn,
                    onChanged: (value) {
                      setState(() {
                        _communicationSettings = _communicationSettings
                            .copyWith(cameraDefaultOn: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Blur background on video'),
                    value: _communicationSettings.blurBackground,
                    onChanged: (value) {
                      setState(() {
                        _communicationSettings = _communicationSettings
                            .copyWith(blurBackground: value);
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save Profile',
                    isLoading: _isSaving,
                    onPressed: () => _saveProfile(authUser.uid),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.go(RouteNames.guidesDirectory),
                    icon: const Icon(Icons.support_agent_outlined),
                    label: const Text('Browse Guides'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(RouteNames.myReviews),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('View My Reviews'),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final isAdminAsync = ref.watch(isAdminProvider);
                      return isAdminAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (isAdmin) {
                          if (!isAdmin) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: OutlinedButton.icon(
                              onPressed: () => context.go(RouteNames.admin),
                              icon: const Icon(Icons.admin_panel_settings_outlined),
                              label: const Text('Admin Panel'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
