import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/utils/validation_util.dart';
import '../../colleges/widgets/college_autocomplete_field.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../communication/widgets/language_multi_select_field.dart';
import '../../community/models/user_presence_model.dart';
import '../widgets/premium_profile_edit_section.dart';
import '../widgets/display_name_settings_section.dart';
import '../widgets/phone_verification_section.dart';
import '../widgets/email_verification_section.dart';

/// Full profile editor. Reached from the Profile hub via "Edit Profile".
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
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
  String? _hydratedUid;

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
        if (context.canPop()) context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: FirestoreErrorUtils.userMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final authUser = ref.watch(currentUserProvider);
    final userDetailAsync = ref.watch(currentUserDetailProvider);
    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please log in to edit your profile'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: userDetailAsync.when(
        loading: () => const Center(child: ProfileHeaderSkeleton()),
        error: (e, _) => AsyncErrorView.fromError(
          e,
          onRetry: () => ref.invalidate(currentUserDetailProvider),
        ),
        data: (userDetail) {
          if (userDetail != null && _hydratedUid != userDetail.uid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _populateFromUser(userDetail);
                _hydratedUid = userDetail.uid;
              });
            });
          }

          final settings =
              _communicationSettings ?? userDetail?.communicationSettings;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              AppSpacing.lg,
              AppSpacing.pageH,
              96,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DisplayNameSettingsSection(),
                  const SizedBox(height: AppSpacing.xl),
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
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Verified Identity',
                    subtitle: 'Your legal name and verified contact details',
                  ),
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
                    isPhoneVerified:
                        _isPhoneVerified || (userDetail?.isPhoneVerified ?? false),
                    onVerified: (phone) {
                      setState(() {
                        _isPhoneVerified = true;
                        _verifiedPhone = phone;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PremiumCard(
                    radius: tokens.cardRadius,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Academic Details',
                          subtitle: 'College, course, and languages you know',
                        ),
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
                      ],
                    ),
                  ),
                  if (settings != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    PremiumCard(
                      radius: tokens.cardRadius,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Guide Settings',
                            subtitle: 'Control how others can connect with you',
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                                'Allow public profile for student connect'),
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
                          Builder(builder: (context) {
                            // Mirrors guideAvailabilityRequiresVerification() in
                            // firestore.rules — the UI gate here is convenience
                            // only; the rule is what actually enforces this.
                            final isEligibleGuide = userDetail != null &&
                                (userDetail.verificationBadge ==
                                        VerificationConstants
                                            .badgeVerifiedStudent ||
                                    userDetail.verificationBadge ==
                                        VerificationConstants
                                            .badgeVerifiedAlumni) &&
                                userDetail.verificationStatus ==
                                    VerificationConstants.statusApproved;
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Available as a guide'),
                              subtitle: isEligibleGuide
                                  ? null
                                  : const Text(
                                      'Only verified students/alumni can become a guide. Complete verification first.',
                                    ),
                              value: settings.isGuideAvailable && isEligibleGuide,
                              onChanged: isEligibleGuide
                                  ? (value) {
                                      setState(() {
                                        _communicationSettings = settings
                                            .copyWith(isGuideAvailable: value);
                                      });
                                    }
                                  : null,
                            );
                          }),
                          if ((_communicationSettings ?? settings)
                              .isGuideAvailable)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    context.push(RouteNames.guidePricingSetup),
                                icon: const Icon(Icons.sell_outlined),
                                label: const Text('Set chat/call prices'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Save Profile',
                    isLoading: _isSaving,
                    onPressed: () => _saveProfile(authUser.uid),
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
