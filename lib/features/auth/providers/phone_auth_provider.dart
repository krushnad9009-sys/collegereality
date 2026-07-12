import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/phone_auth_service.dart';

final phoneAuthServiceProvider = Provider<PhoneAuthService>((ref) {
  final service = PhoneAuthService();
  ref.onDispose(service.dispose);
  return service;
});
