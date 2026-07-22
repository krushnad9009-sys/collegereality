import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/validation_util.dart';
import '../../colleges/widgets/college_autocomplete_field.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../communication/widgets/language_multi_select_field.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../../community/models/user_presence_model.dart';
import '../../profile/widgets/premium_profile_edit_section.dart';
import '../../profile/widgets/trust_score_card.dart';
import '../../profile/models/student_trust_model.dart';
import '../widgets/display_name_settings_section.dart';
import '../widgets/phone_verification_section.dart';
import '../widgets/email_verification_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _branchController = TextEditingController();
  final _aboutController = TextEditingController();
  String? _selectedCollegeId;
  String? _selectedCollegeName;
  int? _batchYear;
  List<String> _languagesKnown = [];
  List<String> _interests = [];
  String _availabilityStatus = ProfileConstants.availabilityAvailable;
  String? _photoURL;
  String? _coverPhotoURL;
  GuideCommunicationSettings? _communicationSettings;
  bool _isPhoneVerified = false;
  String? _verifiedPhone;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _populateFromUser(UserModel user) {
    _nameController.text = user.displayName ?? '';
    _courseController.text = user.course ?? '';
    _branchController.text = user.branch ?? '';
    _aboutController.text = user.aboutMe ?? '';
    _batchYear = user.batchYear;
    _selectedCollegeId = user.collegeId;
    _selectedCollegeName = user.collegeName;
    _languagesKnown = List<String>.from(user.languagesKnown);
    _interests = List<String>.from(user.interests);
    _availabilityStatus = user.presence.availabilityStatus;
    _photoURL = user.photoURL;
    _coverPhotoURL = user.coverPhotoURL;
    _communicationSettings = user.communicationSettings;
    _isPhoneVerified = user.isPhoneVerified;
    _verifiedPhone = user.phone;
  }

  Future<void> _saveProfile(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentDetail = ref.read(currentUserDetailProvider).valueOrNull;
      final authService = ref.read(authServiceProvider);
      await authService.updateUserProfile(
        displayName: _nameController.text.trim(),
        photoURL: _photoURL ?? currentDetail?.photoURL,
      );

      await ref.read(userRepositoryProvider).updateUserProfile(
            uid: uid,
            displayName: _nameController.text.trim(),
            verifiedRealName: _nameController.text.trim(),
            photoURL: _photoURL,
            coverPhotoURL: _coverPhotoURL,
            collegeId: _selectedCollegeId,
            collegeName: _selectedCollegeName,
            course: _courseController.text.trim().isEmpty
                ? null
                : _courseController.text.trim(),
            branch: _branchController.text.trim().isEmpty
                ? null
                : _branchController.text.trim(),
            batchYear: _batchYear,
            aboutMe: _aboutController.text.trim().isEmpty
                ? null
                : _aboutController.text.trim(),
            interests: _interests,
            languagesKnown: _languagesKnown,
            communicationSettings: _communicationSettings,
            presence: UserPresenceModel(
              isOnline: currentDetail?.presence.isOnline ?? false,
              lastSeenAt: DateTime.now(),
              availabilityStatus: _availabilityStatus,
            ),
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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and profile data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await ref.read(userRepositoryProvider).deleteUser(user.uid);
      await user.delete();
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go(RouteNames.login);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'Could not delete account. Sign in again and retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final userDetailAsync = ref.watch(currentUserDetailProvider);
    if (authUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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

          final settings =
              _communicationSettings ?? userDetail?.communicationSettings;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
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
                      backgroundImage: (_photoURL ?? userDetail?.photoURL) != null
                          ? NetworkImage((_photoURL ?? userDetail!.photoURL)!)
                          : null,
                      child: (_photoURL ?? userDetail?.photoURL) == null
                          ? Text(
                              (_nameController.text.isNotEmpty
                                      ? _nameController.text[0]
                                      : authUser.email?[0] ?? 'S')
                                  .toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (userDetail != null &&
                      userDetail.verificationBadge !=
                          VerificationConstants.badgeNone)
                    Center(
                      child: VerificationBadgeWidget(
                        badge: userDetail.verificationBadge,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (userDetail != null)
                    TrustScoreCard(trust: StudentTrustModel.fromUser(userDetail)),
                  const SizedBox(height: 16),
                  const DisplayNameSettingsSection(),
                  const SizedBox(height: 16),
                  PremiumProfileEditSection(
                    user: userDetail ??
                        UserModel(
                          uid: authUser.uid,
                          email: authUser.email ?? '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                    branchController: _branchController,
                    aboutController: _aboutController,
                    interests: _interests,
                    availabilityStatus: _availabilityStatus,
                    onInterestsChanged: (v) => setState(() => _interests = v),
                    onAvailabilityChanged: (v) =>
                        setState(() => _availabilityStatus = v),
                    onPhotoUrlChanged: (url) => setState(() => _photoURL = url),
                    onCoverUrlChanged: (url) =>
                        setState(() => _coverPhotoURL = url),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Verified Real Name',
                    hint: 'Your verified identity (stored securely)',
                    controller: _nameController,
                    validator: ValidationUtil.validateDisplayName,
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  EmailVerificationSection(
                    userId: authUser.uid,
                    email: authUser.email ?? '',
                  ),
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
                  const SizedBox(height: 16),
                  CollegeAutocompleteField(
                    selectedCollegeId: _selectedCollegeId,
                    selectedCollegeName: _selectedCollegeName,
                    onChanged: (college) {
                      setState(() {
                        _selectedCollegeId = college?.id;
                        _selectedCollegeName = college?.name;
                      });
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
                  if (settings != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Guide Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow public profile for student connect'),
                      subtitle: const Text(
                        'Other students can chat with you. Your phone number stays private.',
                      ),
                      value: settings.allowPublicProfile,
                      onChanged: (value) {
                        setState(() {
                          _communicationSettings =
                              settings.copyWith(allowPublicProfile: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available as a guide'),
                      value: settings.isGuideAvailable,
                      onChanged: (value) {
                        setState(() {
                          _communicationSettings =
                              settings.copyWith(isGuideAvailable: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow video calls'),
                      value: settings.videoCallsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _communicationSettings =
                              settings.copyWith(videoCallsEnabled: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Camera on by default'),
                      value: settings.cameraDefaultOn,
                      onChanged: (value) {
                        setState(() {
                          _communicationSettings =
                              settings.copyWith(cameraDefaultOn: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Blur background on video'),
                      value: settings.blurBackground,
                      onChanged: (value) {
                        setState(() {
                          _communicationSettings =
                              settings.copyWith(blurBackground: value);
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    label: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save Profile',
                    isLoading: _isSaving,
                    onPressed: () => _saveProfile(authUser.uid),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      RouteNames.studentProfilePath(authUser.uid),
                    ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Public Profile'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(RouteNames.verification),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Student Verification'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.facultyVerification),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Faculty Verification'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.facultyHub),
                    icon: const Icon(Icons.biotech_outlined),
                    label: const Text('Faculty Hub'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.alumniMentorship),
                    icon: const Icon(Icons.volunteer_activism_outlined),
                    label: const Text('Alumni Mentorship'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.officialCollegeDashboard),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('Official College Dashboard'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.requestCollege),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Add My College'),
                  ),
                  const SizedBox(height: 12),
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
