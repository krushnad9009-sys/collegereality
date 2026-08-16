import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/consultation_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/consultation_model.dart';
import '../providers/consultation_provider.dart';
import '../services/call_access_service.dart';
import '../widgets/two_way_rating_sheet.dart';
import 'consultation_chat_bridge_screen.dart';

/// The single entry point for "what happens after payment" — routes
/// straight into the existing chat engine for chat consultations, and
/// hosts the paid-call state machine (waiting/active/completed) for
/// call/video ones. See CallAccessService doc comment for why this screen
/// stops at "call access granted" rather than a live audio/video stream.
class ConsultationRoomScreen extends ConsumerWidget {
  final String consultationId;
  const ConsultationRoomScreen({required this.consultationId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationAsync = ref.watch(consultationProvider(consultationId));
    final uid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation')),
      body: AsyncStateView(
        value: consultationAsync,
        builder: (c) {
          if (c == null || uid == null) {
            return const AsyncEmptyView(
              icon: Icons.search_off_outlined,
              title: 'Consultation not found',
              subtitle: null,
            );
          }
          if (!c.isParticipant(uid)) {
            return const AsyncEmptyView(
              icon: Icons.lock_outline,
              title: 'Not your consultation',
              subtitle: null,
            );
          }
          if (c.type == ConsultationConstants.typeChat && c.isActive && c.conversationId != null) {
            return ConsultationChatBridgeScreen(consultation: c, currentUid: uid);
          }
          return _CallRoomBody(consultation: c, uid: uid);
        },
      ),
    );
  }
}

class _CallRoomBody extends ConsumerStatefulWidget {
  final ConsultationModel consultation;
  final String uid;
  const _CallRoomBody({required this.consultation, required this.uid});

  @override
  ConsumerState<_CallRoomBody> createState() => _CallRoomBodyState();
}

class _CallRoomBodyState extends ConsumerState<_CallRoomBody> {
  ConsultationCallToken? _token;
  bool _joining = false;
  String? _error;

  bool get _isGuide => widget.uid == widget.consultation.guideId;

  Future<void> _joinCall() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    final consultationService = ref.read(consultationServiceProvider);
    try {
      if (widget.consultation.status == ConsultationConstants.statusPaid) {
        await consultationService.markWaitingForGuide(widget.consultation.id);
      }
      final token = await ref
          .read(callAccessServiceProvider)
          .mintCallToken(widget.consultation.id);
      if (widget.consultation.status != ConsultationConstants.statusActive) {
        await consultationService.markActive(widget.consultation.id);
      }
      if (!mounted) return;
      setState(() => _token = token);
    } on CallAccessException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not join the call.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _endConsultation() async {
    await ref.read(consultationServiceProvider).completeConsultation(widget.consultation.id);
  }

  Future<void> _cancel() async {
    await ref.read(consultationServiceProvider).cancelConsultation(
          consultationId: widget.consultation.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.consultation;
    final tokens = context.tokens;
    final peerId = c.peerIdFor(widget.uid);
    final peerAsync = ref.watch(publicProfileByUidProvider(peerId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          peerAsync.when(
            data: (peer) => Text(
              peer?.displayName ?? peer?.anonymousGuideAlias ?? 'Consultation',
              style: AppFonts.plusJakarta(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            loading: () => const SizedBox(height: 24),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          _StatusStepper(status: c.status),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(
              _error!,
              style: AppFonts.plusJakarta(
                color: AppTheme.errorColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (c.status == ConsultationConstants.statusRequested ||
              c.status == ConsultationConstants.statusPaymentPending)
            const AsyncEmptyView(
              icon: Icons.hourglass_top_outlined,
              title: 'Waiting for payment',
              subtitle: 'Complete checkout to unlock this consultation.',
            )
          else if (c.status == ConsultationConstants.statusPaid ||
              c.status == ConsultationConstants.statusWaitingForGuide)
            PrimaryButton(
              label: c.status == ConsultationConstants.statusWaitingForGuide
                  ? 'Ringing…'
                  : (_isGuide ? 'Start call' : 'Join call'),
              isLoading: _joining,
              onPressed: _joinCall,
            )
          else if (c.status == ConsultationConstants.statusActive) ...[
            if (_token == null)
              PrimaryButton(label: 'Get call access', isLoading: _joining, onPressed: _joinCall)
            else
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Call access granted',
                          style: AppFonts.plusJakarta(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Payment verified and a secure call token was issued for channel '
                      '"${_token!.channelName}". Live audio/video isn\'t wired up in this '
                      'build yet — see functions/README.md for what\'s left (a real-time '
                      'media SDK needs an actual Agora project).',
                      style: AppFonts.plusJakarta(
                        color: tokens.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SecondaryButton(label: 'End consultation', onPressed: _endConsultation),
          ] else if (c.status == ConsultationConstants.statusCompleted)
            _RatingPrompt(consultation: c, uid: widget.uid)
          else
            AsyncEmptyView(
              icon: Icons.info_outline,
              title: c.status == ConsultationConstants.statusCancelled
                  ? 'Cancelled'
                  : 'Expired',
              subtitle: c.cancelReason,
            ),
          if (c.status == ConsultationConstants.statusPaid ||
              c.status == ConsultationConstants.statusWaitingForGuide) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: _cancel, child: const Text('Cancel consultation')),
          ],
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final String status;
  const _StatusStepper({required this.status});

  static const _steps = [
    ConsultationConstants.statusRequested,
    ConsultationConstants.statusPaymentPending,
    ConsultationConstants.statusPaid,
    ConsultationConstants.statusActive,
    ConsultationConstants.statusCompleted,
  ];

  @override
  Widget build(BuildContext context) {
    if (ConsultationConstants.terminalStatuses.contains(status) &&
        status != ConsultationConstants.statusCompleted) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final currentIndex = _steps.indexOf(status).clamp(0, _steps.length - 1);
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Icon(
            i <= currentIndex ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: i <= currentIndex ? primary : tokens.textTertiary,
          ),
          if (i != _steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < currentIndex ? primary : tokens.borderSubtle,
              ),
            ),
        ],
      ],
    );
  }
}

class _RatingPrompt extends ConsumerWidget {
  final ConsultationModel consultation;
  final String uid;
  const _RatingPrompt({required this.consultation, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!consultation.canRate(uid)) {
      return const AsyncEmptyView(
        icon: Icons.check_circle_outline,
        title: 'Consultation completed',
        subtitle: 'Thanks for using College Reality.',
      );
    }
    final isStudent = uid == consultation.studentId;
    final raterRole = isStudent
        ? ConsultationConstants.raterRoleStudent
        : ConsultationConstants.raterRoleGuide;
    final rateeId = isStudent ? consultation.guideId : consultation.studentId;

    return PrimaryButton(
      label: 'Rate this consultation',
      onPressed: () => showTwoWayRatingSheet(
        context: context,
        consultationId: consultation.id,
        raterId: uid,
        raterRole: raterRole,
        rateeId: rateeId,
        rateeLabel: isStudent ? 'the guide' : 'the student',
      ),
    );
  }
}
