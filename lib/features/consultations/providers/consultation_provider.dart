import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../social/models/social_models.dart';
import '../models/consultation_model.dart';
import '../models/consultation_rating_model.dart';
import '../services/call_access_service.dart';
import '../services/consultation_service.dart';
import '../services/payment_service.dart';
import '../utils/consultation_rating_calculator.dart';

final consultationServiceProvider =
    Provider<ConsultationService>((ref) => ConsultationService());

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

final callAccessServiceProvider =
    Provider<CallAccessService>((ref) => CallAccessService());

final consultationProvider =
    StreamProvider.family<ConsultationModel?, String>((ref, consultationId) {
  return ref.watch(consultationServiceProvider).watchConsultation(consultationId);
});

final consultationRatingProvider = StreamProvider.family<ConsultationRatingModel?,
    ({String consultationId, String raterRole})>((ref, args) {
  return ref
      .watch(consultationServiceProvider)
      .watchRating(args.consultationId, args.raterRole);
});

final studentConsultationSummaryProvider =
    FutureProvider.family<StudentConsultationSummary, String>((ref, studentId) {
  return ref
      .watch(consultationServiceProvider)
      .getStudentConsultationSummary(studentId);
});

/// First page of consultation history (student or guide side). Callers
/// load further pages via ConsultationService.fetchHistoryPage directly
/// with the returned `lastDocument`, same pagination pattern used for
/// notifications/messages elsewhere in the app.
final consultationHistoryFirstPageProvider = FutureProvider.family<
    SocialPageResult<ConsultationModel>,
    ({String userId, bool asGuide})>((ref, args) {
  return ref.watch(consultationServiceProvider).fetchHistoryPage(
        userId: args.userId,
        asGuide: args.asGuide,
      );
});
