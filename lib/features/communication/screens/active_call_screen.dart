import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/interaction_rating_model.dart';
import '../providers/communication_provider.dart';
import '../services/communication_firestore_service.dart';
import '../utils/communication_formatters.dart';
import '../widgets/post_interaction_rating_sheet.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ActiveCallScreen({required this.sessionId, super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  Timer? _durationTimer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;
  bool _isMuted = false;
  bool _cameraOff = false;
  bool _blurBackground = true;
  bool _ratingShown = false;

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int maxSeconds) {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= maxSeconds) {
        _endCall(emergency: false, limitReached: true);
      }
    });
  }

  Future<void> _endCall({
    required bool emergency,
    bool limitReached = false,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _durationTimer?.cancel();
    try {
      await ref.read(communicationServiceProvider).endCall(
            sessionId: widget.sessionId,
            userId: user.uid,
            emergency: emergency,
          );
    } on CommunicationException catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    }

    if (limitReached && mounted) {
      SnackBarHelper.showInfoSnackBar(
        context,
        message: 'Call duration limit reached for your subscription.',
      );
    }
  }

  Future<void> _showRatingIfNeeded(
    dynamic session,
    String userId,
  ) async {
    if (_ratingShown || session == null) return;
    final isEnded = session.status == CommunicationConstants.callStatusEnded ||
        session.status == CommunicationConstants.callStatusEmergencyEnded;
    if (!isEnded) return;

    final alreadyRated = userId == session.callerId
        ? session.ratingsSubmittedCaller
        : session.ratingsSubmittedCallee;
    if (alreadyRated) return;

    _ratingShown = true;
    final peerAlias = session.peerAliasFor(userId);
    final peerId = session.peerIdFor(userId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PostInteractionRatingSheet(
        peerAlias: peerAlias,
        onSubmit: (partial) async {
          await ref.read(communicationServiceProvider).submitInteractionRating(
                rating: InteractionRatingModel(
                  id: '',
                  sessionId: widget.sessionId,
                  raterId: userId,
                  rateeId: peerId,
                  stars: partial.stars,
                  helpful: partial.helpful,
                  respectful: partial.respectful,
                  wouldRecommend: partial.wouldRecommend,
                  interactionType: session.isVideo ? 'video_call' : 'voice_call',
                  createdAt: DateTime.now(),
                ),
                incrementCall: true,
              );
        },
      ),
    );

    if (mounted) context.go(RouteNames.home);
  }

  Future<void> _reportDuringCall(String peerId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(communicationServiceProvider).reportUser(
          reporterId: user.uid,
          reportedId: peerId,
          reason: 'In-call report',
          sessionId: widget.sessionId,
        );
    if (mounted) {
      SnackBarHelper.showSuccessSnackBar(context, message: 'Report submitted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final sessionAsync = ref.watch(callSessionProvider(widget.sessionId));

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.gray900,
        body: Center(
          child: Text(
            'Please log in',
            style: AppFonts.plusJakarta(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return sessionAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.gray900,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.gray900,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white54, size: 40),
                const SizedBox(height: 12),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakarta(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            backgroundColor: AppTheme.gray900,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'Call session not found',
                style: AppFonts.plusJakarta(color: Colors.white70, fontSize: 14),
              ),
            ),
          );
        }

        if (session.status == CommunicationConstants.callStatusActive &&
            !_timerStarted &&
            session.startedAt != null) {
          _timerStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startTimer(session.maxDurationSeconds);
          });
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRatingIfNeeded(session, user.uid);
        });

        final peerAlias = session.peerAliasFor(user.uid);
        final peerId = session.peerIdFor(user.uid);
        final isCaller = session.callerId == user.uid;
        final needsAccept = !session.bothAccepted &&
            ((isCaller && !session.callerAccepted) ||
                (!isCaller && !session.calleeAccepted));

        return Scaffold(
          backgroundColor: AppTheme.gray900,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(session.isVideo ? 'Video Call' : 'Voice Call'),
            actions: [
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _reportDuringCall(peerId),
                tooltip: 'Report',
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  if (session.isVideo)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.gray800, AppTheme.gray700],
                              ),
                            ),
                            child: _cameraOff
                                ? const Icon(Icons.videocam_off_rounded,
                                    size: 64, color: Colors.white54)
                                : Icon(Icons.person_rounded,
                                    size: 80,
                                    color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          if (_blurBackground && !_cameraOff)
                            Container(
                              width: double.infinity,
                              height: 220,
                              color: Colors.black.withValues(alpha: 0.2),
                              child: Center(
                                child: Text(
                                  'Background blurred',
                                  style: AppFonts.plusJakarta(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          peerAlias.replaceAll('Guide #', '').substring(0, 2),
                          style: AppFonts.plusJakarta(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    peerAlias,
                    style: AppFonts.plusJakarta(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(session.status, needsAccept),
                      style: AppFonts.plusJakarta(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (session.status ==
                      CommunicationConstants.callStatusActive) ...[
                    const SizedBox(height: 20),
                    Text(
                      formatCallDuration(_elapsedSeconds),
                      style: AppFonts.plusJakarta(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Max ${formatCallDuration(session.maxDurationSeconds)}',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (needsAccept && !isCaller)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallActionButton(
                          icon: Icons.call_end,
                          label: 'Decline',
                          color: AppTheme.errorColor,
                          onTap: () async {
                            await ref
                                .read(communicationServiceProvider)
                                .rejectCall(
                                  sessionId: widget.sessionId,
                                  userId: user.uid,
                                );
                            if (!context.mounted) return;
                            context.pop();
                          },
                        ),
                        _CallActionButton(
                          icon: Icons.call,
                          label: 'Accept',
                          color: AppTheme.accentColor,
                          onTap: () async {
                            await ref
                                .read(communicationServiceProvider)
                                .acceptCall(
                                  sessionId: widget.sessionId,
                                  userId: user.uid,
                                );
                          },
                        ),
                      ],
                    )
                  else if (session.status ==
                          CommunicationConstants.callStatusRequested &&
                      isCaller)
                    Text(
                      'Waiting for guide to accept…',
                      style: AppFonts.plusJakarta(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (session.status ==
                      CommunicationConstants.callStatusActive)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _CallControl(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onTap: () => setState(() => _isMuted = !_isMuted),
                        ),
                        if (session.isVideo) ...[
                          _CallControl(
                            icon: _cameraOff
                                ? Icons.videocam_off
                                : Icons.videocam,
                            label: _cameraOff ? 'Camera on' : 'Camera off',
                            onTap: () =>
                                setState(() => _cameraOff = !_cameraOff),
                          ),
                          _CallControl(
                            icon: Icons.blur_on,
                            label: _blurBackground ? 'Blur on' : 'Blur off',
                            onTap: () => setState(
                              () => _blurBackground = !_blurBackground,
                            ),
                          ),
                        ],
                        _CallControl(
                          icon: Icons.warning_amber_rounded,
                          label: 'Emergency',
                          color: AppTheme.warningColor,
                          onTap: () async {
                            await _endCall(emergency: true);
                          },
                        ),
                        _CallControl(
                          icon: Icons.call_end,
                          label: 'End',
                          color: AppTheme.errorColor,
                          onTap: () => _endCall(emergency: false),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String status, bool needsAccept) {
    switch (status) {
      case CommunicationConstants.callStatusRequested:
        return needsAccept ? 'Incoming call request' : 'Calling…';
      case CommunicationConstants.callStatusAccepted:
        return 'Connecting…';
      case CommunicationConstants.callStatusActive:
        return 'Connected — in-app only, no numbers shared';
      case CommunicationConstants.callStatusEnded:
        return 'Call ended';
      case CommunicationConstants.callStatusEmergencyEnded:
        return 'Call ended (emergency)';
      case CommunicationConstants.callStatusRejected:
        return 'Call declined';
      default:
        return status;
    }
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppFonts.plusJakarta(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: (color ?? Colors.white24),
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: color == null
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color!.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.plusJakarta(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
