import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/display_name_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/public_display_name_utils.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/screens/display_name_setup_screen.dart';
import '../../auth/utils/validation_util.dart';
import '../../verification/widgets/verification_badge_widget.dart';

class DisplayNameSettingsSection extends ConsumerStatefulWidget {
  const DisplayNameSettingsSection({super.key});

  @override
  ConsumerState<DisplayNameSettingsSection> createState() =>
      _DisplayNameSettingsSectionState();
}

class _DisplayNameSettingsSectionState
    extends ConsumerState<DisplayNameSettingsSection> {
  String? _selectedMode;
  final _customNameController = TextEditingController();
  bool _isSaving = false;
  String? _customNameError;

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  void _syncFromUser(UserModel user) {
    _selectedMode ??= user.displayNameMode;
    if (_customNameController.text.isEmpty) {
      _customNameController.text = user.customDisplayName ?? '';
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

  Future<void> _save(UserModel user) async {
    final mode = _selectedMode ?? user.displayNameMode;
    if (mode == DisplayNameConstants.modeCustom) {
      final error = ValidationUtil.validateCustomDisplayName(
        _customNameController.text.trim(),
      );
      if (error != null) {
        setState(() => _customNameError = error);
        return;
      }
    }

    if (!canChangeDisplayName(user.displayNameChangedAt) &&
        (mode != user.displayNameMode ||
            (mode == DisplayNameConstants.modeCustom &&
                _customNameController.text.trim() != user.customDisplayName))) {
      final daysLeft = daysUntilDisplayNameChange(user.displayNameChangedAt);
      SnackBarHelper.showErrorSnackBar(
        context,
        message:
            'Display name can only be changed once every ${DisplayNameConstants.changeCooldownDays} days. Try again in $daysLeft day(s).',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _customNameError = null;
    });

    try {
      await ref.read(displayNameServiceProvider).updateDisplayNameSettings(
            user: user,
            displayNameMode: mode,
            customDisplayName:
                mode == DisplayNameConstants.modeCustom
                    ? _customNameController.text.trim()
                    : null,
          );
      ref.invalidate(currentUserDetailProvider);
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          message: 'Public display name updated.',
        );
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

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        _syncFromUser(user);

        final canChange = canChangeDisplayName(user.displayNameChangedAt);
        final daysLeft = daysUntilDisplayNameChange(user.displayNameChangedAt);
        final preview = computePublicDisplayName(
          userId: user.uid,
          verifiedRealName: user.verifiedRealName ?? user.displayName,
          displayNameMode: _selectedMode ?? user.displayNameMode,
          customDisplayName: _customNameController.text.trim(),
          verificationBadge: user.verificationBadge,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public Display Name',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your verified identity (${user.verifiedRealName ?? user.displayName ?? 'not set'}) is stored securely and never shown publicly unless you choose Real Name.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.gray500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ..._availableModes(user).map((mode) {
                  return RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: mode,
                    groupValue: _selectedMode,
                    onChanged: canChange
                        ? (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedMode = value;
                              _customNameError = null;
                            });
                          }
                        : null,
                    title: Text(
                      displayNameModeLabel(mode),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  );
                }),
                if ((_selectedMode ?? user.displayNameMode) ==
                    DisplayNameConstants.modeCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customNameController,
                    enabled: canChange,
                    decoration: InputDecoration(
                      labelText: 'Custom Display Name',
                      errorText: _customNameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Currently shown as: ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.gray500,
                      ),
                    ),
                    Text(
                      preview,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.verificationBadge !=
                        VerificationConstants.badgeNone) ...[
                      const SizedBox(width: 6),
                      VerificationBadgeWidget(
                        badge: user.verificationBadge,
                        iconSize: 14,
                      ),
                    ],
                  ],
                ),
                if (!canChange) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You can change your display name again in $daysLeft day(s).',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSaving || !canChange ? null : () => _save(user),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Display Name'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
