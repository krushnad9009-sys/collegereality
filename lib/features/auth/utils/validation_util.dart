import 'package:email_validator/email_validator.dart';

import '../../social/utils/moderation_utils.dart';
import '../../../core/constants/display_name_constants.dart';

class ValidationUtil {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Password must contain lowercase letters';
    }

    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain uppercase letters';
    }

    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'Password must contain numbers';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
    String? value,
    String? password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Phone validation (Indian format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');

    if (cleanPhone.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      return 'Please enter a valid Indian phone number';
    }

    return null;
  }

  // Display name validation
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name must not exceed 50 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    if (containsOffensiveContent(value)) {
      return 'Name contains inappropriate language';
    }

    return null;
  }

  static String? validateCustomDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Custom display name is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < DisplayNameConstants.customNameMinLength) {
      return 'Display name must be at least ${DisplayNameConstants.customNameMinLength} characters';
    }

    if (trimmed.length > DisplayNameConstants.customNameMaxLength) {
      return 'Display name must not exceed ${DisplayNameConstants.customNameMaxLength} characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9 _.-]+$').hasMatch(trimmed)) {
      return 'Display name can only contain letters, numbers, spaces, dots, and hyphens';
    }

    if (containsOffensiveContent(trimmed)) {
      return 'Display name contains inappropriate language';
    }

    final lower = trimmed.toLowerCase();
    for (final reserved in [
      'admin',
      'moderator',
      'college reality',
      'anonymous verified student',
      'anonymous verified alumni',
    ]) {
      if (lower.contains(reserved)) {
        return 'This display name is not allowed';
      }
    }

    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Check if password is strong
  static bool isPasswordStrong(String password) {
    return validatePassword(password) == null;
  }

  // Check if email is valid
  static bool isEmailValid(String email) {
    return validateEmail(email) == null;
  }

  // Check if phone is valid
  static bool isPhoneValid(String phone) {
    return validatePhone(phone) == null;
  }
}
