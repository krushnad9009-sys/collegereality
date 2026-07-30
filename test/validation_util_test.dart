import 'package:college_reality_india/features/auth/utils/validation_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationUtil.email', () {
    test('requires email', () {
      expect(ValidationUtil.validateEmail(null), 'Email is required');
      expect(ValidationUtil.validateEmail(''), 'Email is required');
    });

    test('rejects invalid email', () {
      expect(
        ValidationUtil.validateEmail('not-an-email'),
        'Please enter a valid email address',
      );
    });

    test('accepts valid email', () {
      expect(ValidationUtil.validateEmail('student@college.edu'), isNull);
      expect(ValidationUtil.isEmailValid('student@college.edu'), isTrue);
      expect(ValidationUtil.isEmailValid('bad'), isFalse);
    });
  });

  group('ValidationUtil.password', () {
    test('requires password and min length', () {
      expect(ValidationUtil.validatePassword(null), 'Password is required');
      expect(
        ValidationUtil.validatePassword('Ab1'),
        'Password must be at least 8 characters',
      );
    });

    test('requires mixed case and numbers', () {
      expect(
        ValidationUtil.validatePassword('abcdefgh'),
        'Password must contain uppercase letters',
      );
      expect(
        ValidationUtil.validatePassword('ABCDEFGH'),
        'Password must contain lowercase letters',
      );
      expect(
        ValidationUtil.validatePassword('Abcdefgh'),
        'Password must contain numbers',
      );
    });

    test('accepts strong password', () {
      expect(ValidationUtil.validatePassword('College1'), isNull);
      expect(ValidationUtil.isPasswordStrong('College1'), isTrue);
      expect(ValidationUtil.isPasswordStrong('weak'), isFalse);
    });
  });

  group('ValidationUtil.confirmPassword', () {
    test('requires confirmation and match', () {
      expect(
        ValidationUtil.validateConfirmPassword(null, 'College1'),
        'Please confirm your password',
      );
      expect(
        ValidationUtil.validateConfirmPassword('College2', 'College1'),
        'Passwords do not match',
      );
      expect(
        ValidationUtil.validateConfirmPassword('College1', 'College1'),
        isNull,
      );
    });
  });

  group('ValidationUtil.phone', () {
    test('requires 10-digit Indian mobile', () {
      expect(ValidationUtil.validatePhone(null), 'Phone number is required');
      expect(
        ValidationUtil.validatePhone('12345'),
        'Phone number must be 10 digits',
      );
      expect(
        ValidationUtil.validatePhone('5123456789'),
        'Please enter a valid Indian phone number',
      );
      expect(ValidationUtil.validatePhone('9876543210'), isNull);
      // Country code makes digit count != 10 after stripping non-digits.
      expect(
        ValidationUtil.validatePhone('+91 98765-43210'),
        'Phone number must be 10 digits',
      );
      expect(ValidationUtil.isPhoneValid('9876543210'), isTrue);
    });
  });

  group('ValidationUtil.displayName', () {
    test('validates length and characters', () {
      expect(ValidationUtil.validateDisplayName(null), 'Name is required');
      expect(
        ValidationUtil.validateDisplayName('A'),
        'Name must be at least 2 characters',
      );
      expect(
        ValidationUtil.validateDisplayName('Rahul123'),
        'Name can only contain letters and spaces',
      );
      expect(ValidationUtil.validateDisplayName('Rahul Sharma'), isNull);
    });
  });

  group('ValidationUtil.required', () {
    test('uses field name in message', () {
      expect(ValidationUtil.validateRequired(null, 'City'), 'City is required');
      expect(ValidationUtil.validateRequired('Pune', 'City'), isNull);
    });
  });
}