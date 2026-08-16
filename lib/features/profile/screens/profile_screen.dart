import 'package:firebase_auth/firebase_auth.dart';
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
import '../widgets/profile_settings_section.dart';
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
    final tokens = context.tokens;
    final authUser = ref.watch(currentUserProvider);
    final userDetailAsync = ref.watch(currentUserDetailProvider);
    if (authUser == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please log in to view your profile'),
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
          'My Profile',
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
              0,
              AppSpacing.pageH,
              96,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeaderSection(
                    photoUrl: _photoURL ?? userDetail?.photoURL,
                    coverUrl: _coverPhotoURL ?? userDetail?.coverPhotoURL,
                    displayName: _nameController.text.isNotEmpty
                        ? _nameController.text
                        : (userDetail?.displayName ?? authUser.email ?? 'Student'),
                    email: authUser.email ?? '',
                    verificationBadge: userDetail?.verificationBadge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (userDetail != null)
                    TrustScoreCard(trust: StudentTrustModel.fromUser(userDetail)),
                  const SizedBox(height: AppSpacing.xl),
                  const DisplayNameSettingsSection(),
                  const ProfileSettingsSection(),
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
                          Builder(builder: (context) {
                            // Mirrors guideAvailabilityRequiresVerification() in
                            // firestore.rules — the UI gate here is convenience
                            // only; the rule is what actually enforces this.
                            final isEligibleGuide = userDetail != null &&
                                (userDetail.verificationBadge ==
                                        VerificationConstants.badgeVerifiedStudent ||
                                    userDetail.verificationBadge ==
                                        VerificationConstants.badgeVerifiedAlumni) &&
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
                          if ((_communicationSettings ?? settings).isGuideAvailable)
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
                  const SizedBox(height: AppSpacing.xxl),
                  PremiumCard(
                    radius: tokens.cardRadius,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      children: _withDividers(context, [
                        PremiumListRow(
                          leadingIcon: Icons.visibility_outlined,
                          title: 'View Public Profile',
                          subtitle: 'See how students see your profile',
                          onTap: () => context.push(
                            RouteNames.studentProfilePath(authUser.uid),
                          ),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.forum_outlined,
                          title: 'My Consultations',
                          onTap: () =>
                              context.push(RouteNames.consultationHistory),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.verified_user_outlined,
                          title: 'Student Verification',
                          onTap: () => context.go(RouteNames.verification),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.school_outlined,
                          title: 'Faculty Verification',
                          onTap: () =>
                              context.push(RouteNames.facultyVerification),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.biotech_outlined,
                          title: 'Faculty Hub',
                          onTap: () => context.push(RouteNames.facultyHub),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.volunteer_activism_outlined,
                          title: 'Alumni Mentorship',
                          onTap: () =>
                              context.push(RouteNames.alumniMentorship),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PremiumCard(
                    radius: tokens.cardRadius,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      children: _withDividers(context, [
                        PremiumListRow(
                          leadingIcon: Icons.dashboard_outlined,
                          title: 'Official College Dashboard',
                          onTap: () =>
                              context.push(RouteNames.officialCollegeDashboard),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.add_business_outlined,
                          title: 'Add My College',
                          onTap: () => context.push(RouteNames.requestCollege),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.support_agent_outlined,
                          title: 'Browse Guides',
                          onTap: () => context.go(RouteNames.guidesDirectory),
                        ),
                        PremiumListRow(
                          leadingIcon: Icons.rate_review_outlined,
                          title: 'View My Reviews',
                          onTap: () => context.go(RouteNames.myReviews),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final isAdminAsync = ref.watch(isAdminProvider);
                            return isAdminAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (e, _) => const SizedBox.shrink(),
                              data: (isAdmin) {
                                if (!isAdmin) return const SizedBox.shrink();
                                return PremiumListRow(
                                  leadingIcon:
                                      Icons.admin_panel_settings_outlined,
                                  title: 'Admin Panel',
                                  onTap: () => context.go(RouteNames.admin),
                                );
                              },
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PremiumCard(
                    radius: tokens.cardRadius,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: PremiumListRow(
                      leadingIcon: Icons.delete_forever_outlined,
                      iconColor: Colors.red,
                      titleColor: Colors.red,
                      title: 'Delete Account',
                      showChevron: false,
                      onTap: _confirmDeleteAccount,
                    ),
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

/// Inserts a thin divider between rows inside a [PremiumCard]-wrapped list.
List<Widget> _withDividers(BuildContext context, List<Widget> rows) {
  final tokens = context.tokens;
  final result = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    if (i > 0) {
      result.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Divider(color: tokens.borderSubtle, height: 1),
      ));
    }
    result.add(rows[i]);
  }
  return result;
}

class _ProfileHeaderSection extends StatelessWidget {
  final String? photoUrl;
  final String? coverUrl;
  final String displayName;
  final String email;
  final String? verificationBadge;

  const _ProfileHeaderSection({
    required this.photoUrl,
    required this.coverUrl,
    required this.displayName,
    required this.email,
    required this.verificationBadge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'S');

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(tokens.cardRadius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary,
                    primary.withValues(alpha: 0.75),
                  ],
                ),
                image: coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(coverUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.35),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: -44,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.surfaceElevated,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? Text(
                          initial,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56),
        Text(
          displayName,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            style: textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (verificationBadge != null &&
            verificationBadge != VerificationConstants.badgeNone) ...[
          const SizedBox(height: AppSpacing.md),
          VerificationBadgeWidget(badge: verificationBadge!),
        ],
      ],
    );
  }
}
