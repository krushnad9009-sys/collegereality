import '../constants/display_name_constants.dart';
import '../constants/verification_constants.dart';
import '../../features/auth/models/user_model.dart';

String buildAnonymousVerifiedStudentAlias(String userId) {
  final hash = userId.hashCode.abs() % 10000;
  return '${DisplayNameConstants.anonymousVerifiedStudentLabel} #$hash';
}

String buildAnonymousVerifiedAlumniAlias(String userId) {
  final hash = userId.hashCode.abs() % 10000;
  return '${DisplayNameConstants.anonymousVerifiedAlumniLabel} #$hash';
}

String normalizeCustomDisplayNameKey(String name) {
  return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

bool isAnonymousDisplayNameMode(String mode) {
  return mode == DisplayNameConstants.modeAnonymousVerifiedStudent ||
      mode == DisplayNameConstants.modeAnonymousVerifiedAlumni;
}

String resolvePublicDisplayName({
  required String userId,
  required String? verifiedRealName,
  required String? publicDisplayName,
  required String displayNameMode,
  required String? customDisplayName,
  required String verificationBadge,
  String? legacyDisplayName,
}) {
  final stored = publicDisplayName?.trim();
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }

  return computePublicDisplayName(
    userId: userId,
    verifiedRealName: verifiedRealName ?? legacyDisplayName,
    displayNameMode: displayNameMode,
    customDisplayName: customDisplayName,
    verificationBadge: verificationBadge,
  );
}

String computePublicDisplayName({
  required String userId,
  required String? verifiedRealName,
  required String displayNameMode,
  required String? customDisplayName,
  required String verificationBadge,
}) {
  switch (displayNameMode) {
    case DisplayNameConstants.modeAnonymousVerifiedStudent:
      return buildAnonymousVerifiedStudentAlias(userId);
    case DisplayNameConstants.modeAnonymousVerifiedAlumni:
      return buildAnonymousVerifiedAlumniAlias(userId);
    case DisplayNameConstants.modeCustom:
      final custom = customDisplayName?.trim();
      if (custom != null && custom.isNotEmpty) {
        return custom;
      }
      break;
    case DisplayNameConstants.modeRealName:
    default:
      final real = verifiedRealName?.trim();
      if (real != null && real.isNotEmpty) {
        return real;
      }
  }

  if (verificationBadge == VerificationConstants.badgeVerifiedAlumni) {
    return buildAnonymousVerifiedAlumniAlias(userId);
  }
  if (verificationBadge == VerificationConstants.badgeVerifiedStudent) {
    return buildAnonymousVerifiedStudentAlias(userId);
  }

  final fallback = verifiedRealName?.trim();
  if (fallback != null && fallback.isNotEmpty) {
    return fallback;
  }
  return 'Student #${userId.hashCode.abs() % 10000}';
}

String resolvePublicDisplayNameFromUser(UserModel user) {
  return resolvePublicDisplayName(
    userId: user.uid,
    verifiedRealName: user.verifiedRealName ?? user.displayName,
    publicDisplayName: user.publicDisplayName,
    displayNameMode: user.displayNameMode,
    customDisplayName: user.customDisplayName,
    verificationBadge: user.verificationBadge,
    legacyDisplayName: user.displayName,
  );
}

bool canChangeDisplayName(DateTime? lastChangedAt, {DateTime? now}) {
  if (lastChangedAt == null) return true;
  final current = now ?? DateTime.now();
  return current.difference(lastChangedAt).inDays >=
      DisplayNameConstants.changeCooldownDays;
}

int daysUntilDisplayNameChange(DateTime? lastChangedAt, {DateTime? now}) {
  if (lastChangedAt == null) return 0;
  final current = now ?? DateTime.now();
  final elapsed = current.difference(lastChangedAt).inDays;
  final remaining = DisplayNameConstants.changeCooldownDays - elapsed;
  return remaining > 0 ? remaining : 0;
}

String displayNameModeLabel(String mode) {
  switch (mode) {
    case DisplayNameConstants.modeRealName:
      return 'Real Name';
    case DisplayNameConstants.modeAnonymousVerifiedStudent:
      return DisplayNameConstants.anonymousVerifiedStudentLabel;
    case DisplayNameConstants.modeAnonymousVerifiedAlumni:
      return DisplayNameConstants.anonymousVerifiedAlumniLabel;
    case DisplayNameConstants.modeCustom:
      return 'Custom Display Name';
    default:
      return 'Real Name';
  }
}

String? defaultDisplayNameModeForBadge(String verificationBadge) {
  if (verificationBadge == VerificationConstants.badgeVerifiedAlumni) {
    return DisplayNameConstants.modeAnonymousVerifiedAlumni;
  }
  if (verificationBadge == VerificationConstants.badgeVerifiedStudent) {
    return DisplayNameConstants.modeAnonymousVerifiedStudent;
  }
  return DisplayNameConstants.modeRealName;
}
