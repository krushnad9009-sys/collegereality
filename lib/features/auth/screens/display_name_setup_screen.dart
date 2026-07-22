import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/display_name_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/public_display_name_utils.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/services/display_name_service.dart';
import '../../auth/utils/validation_util.dart';
import '../../verification/widgets/verification_badge_widget.dart';

final displayNameServiceProvider = Provider<DisplayNameService>((ref) {
  return DisplayNameService();
});

class DisplayNameSetupScreen extends ConsumerStatefulWidget {
  const DisplayNameSetupScreen({super.key});

  @override
  ConsumerState<DisplayNameSetupScreen> createState() =>
      _DisplayNameSetupScreenState();
}

class _DisplayNameSetupScreenState extends ConsumerState<DisplayNameSetupScreen> {
  final _customNameController = TextEditingController();
  String _selectedMode = DisplayNameConstants.modeRealName;
  bool _isSaving = false;
  bool _initialized = false;
  String? _customNameError;

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  void _initFromUser(UserModel user) {
    if (_initialized) return;
    _initialized = true;
    _selectedMode = user.displayNameMode;
    _customNameController.text = user.customDisplayName ?? '';
    if (!user.displayNameSetupComplete) {
      _selectedMode = defaultDisplayNameModeForBadge(user.verificationBadge) ??
          DisplayNameConstants.modeRealName;
    }
  }

  List<String> _availableModes(UserModel user) {
    final modes = <String>[DisplayNameConstants.modeRealName];
    if (user.verificationBadge == VerificationConstants.badgeVerifiedStudent) {
      modes.add(DisplayNameConstants.modeAnonymousVerifiedStudent);
    }
    if (user.verificationBadge == VerificationConstants.badgeVerifiedAlumni) {
      modes.add(DisplayNameConstants.modeAnonymousVerifiedAlumni);
    }
    modes.add(DisplayNameConstants.modeCustom);
    return modes;
  }

  String _previewName(UserModel user) {
    return computePublicDisplayName(
      userId: user.uid,
      verifiedRealName: user.verifiedRealName ?? user.displayName,
      displayNameMode: _selectedMode,
      customDisplayName: _customNameController.text.trim(),
      verificationBadge: user.verificationBadge,
    );
  }

  Future<void> _save(UserModel user) async {
    if (_selectedMode == DisplayNameConstants.modeCustom) {
      final error = ValidationUtil.validateCustomDisplayName(
        _customNameController.text.trim(),
      );
      if (error != null) {
        setState(() => _customNameError = error);
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _customNameError = null;
    });

    try {
      await ref.read(displayNameServiceProvider).updateDisplayNameSettings(
            user: user,
            displayNameMode: _selectedMode,
            customDisplayName: _selectedMode ==
                    DisplayNameConstants.modeCustom
                ? _customNameController.text.trim()
                : null,
            isInitialSetup: !user.displayNameSetupComplete,
          );

      ref.invalidate(currentUserDetailProvider);

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Public display name saved!',
        );
        context.go(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Public Display Name',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in to continue.'));
          }

          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _initFromUser(user));
              }
            });
          }

          final modes = _availableModes(user);
          final preview = _previewName(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How should you appear publicly?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your verified identity is stored securely. Only your chosen display name is shown in reviews, Q&A, community posts, comments, and chat.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.gray500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ...modes.map((mode) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedMode == mode
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        width: _selectedMode == mode ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: mode,
                      groupValue: _selectedMode,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedMode = value;
                          _customNameError = null;
                        });
                      },
                      title: Text(
                        displayNameModeLabel(mode),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _modeDescription(mode, user),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.gray500,
                        ),
                      ),
                    ),
                  );
                }),
                if (_selectedMode == DisplayNameConstants.modeCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customNameController,
                    decoration: InputDecoration(
                      labelText: 'Custom Display Name',
                      hintText: 'e.g. CampusExplorer',
                      errorText: _customNameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Must be unique. You can change it once every ${DisplayNameConstants.changeCooldownDays} days.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (user.verificationBadge !=
                              VerificationConstants.badgeNone)
                            VerificationBadgeWidget(
                              badge: user.verificationBadge,
                              iconSize: 14,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _modeDescription(String mode, UserModel user) {
    switch (mode) {
      case DisplayNameConstants.modeRealName:
        return 'Show your verified name: ${user.verifiedRealName ?? user.displayName ?? 'Add your name in profile'}';
      case DisplayNameConstants.modeAnonymousVerifiedStudent:
        return 'Hide your name while keeping your verified student badge visible.';
      case DisplayNameConstants.modeAnonymousVerifiedAlumni:
        return 'Hide your name while keeping your verified alumni badge visible.';
      case DisplayNameConstants.modeCustom:
        return 'Choose a unique public nickname.';
      default:
        return '';
    }
  }
}
