import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/consultation_constants.dart';
import '../../community/screens/chat_screen.dart';
import '../models/consultation_model.dart';
import '../providers/consultation_provider.dart';
import '../widgets/two_way_rating_sheet.dart';

/// Wraps the existing private community chat with a paid-consultation
/// "End & rate" action — the chat UI itself (messages, typing, presence,
/// pagination) is 100% the existing ChatScreen, unmodified. Nothing about
/// paid chat duplicates the messaging engine.
class ConsultationChatBridgeScreen extends ConsumerWidget {
  final ConsultationModel consultation;
  final String currentUid;

  const ConsultationChatBridgeScreen({
    required this.consultation,
    required this.currentUid,
    super.key,
  });

  Future<void> _endAndRate(BuildContext context, WidgetRef ref) async {
    await ref.read(consultationServiceProvider).completeConsultation(consultation.id);
    if (!context.mounted) return;
    final isStudent = currentUid == consultation.studentId;
    await showTwoWayRatingSheet(
      context: context,
      consultationId: consultation.id,
      raterId: currentUid,
      raterRole: isStudent
          ? ConsultationConstants.raterRoleStudent
          : ConsultationConstants.raterRoleGuide,
      rateeId: isStudent ? consultation.guideId : consultation.studentId,
      rateeLabel: isStudent ? 'the guide' : 'the student',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          ChatScreen(conversationId: consultation.conversationId!),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: SafeArea(
              child: FilledButton.tonal(
                onPressed: () => _endAndRate(context, ref),
                child: const Text('End & rate'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
