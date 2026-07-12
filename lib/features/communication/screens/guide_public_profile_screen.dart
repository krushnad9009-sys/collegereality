import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/communication_provider.dart';
import '../services/communication_firestore_service.dart';
import '../widgets/guide_stats_display.dart';

class GuidePublicProfileScreen extends ConsumerStatefulWidget {
  final String guideUid;

  const GuidePublicProfileScreen({required this.guideUid, super.key});

  @override
  ConsumerState<GuidePublicProfileScreen> createState() =>
      _GuidePublicProfileScreenState();
}

class _GuidePublicProfileScreenState
    extends ConsumerState<GuidePublicProfileScreen> {
  bool _isRequestingCall = false;

  Future<void> _startCall(String callType) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (user.uid == widget.guideUid) {
      SnackBarHelper.showErrorSnackBar(
        context,
        message: 'You cannot call yourself.',
      );
      return;
    }

    setState(() => _isRequestingCall = true);
    try {
      final service = ref.read(communicationServiceProvider);
      final session = await service.requestCall(
        callerId: user.uid,
        calleeId: widget.guideUid,
        callType: callType,
      );
      if (mounted) {
        context.push(RouteNames.activeCallPath(session.id));
      }
    } on CommunicationException catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isRequestingCall = false);
    }
  }

  Future<void> _blockGuide() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block this guide?'),
        content: const Text(
          'You will no longer be able to call or interact with this guide.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(communicationServiceProvider).blockUser(
          blockerId: user.uid,
          blockedId: widget.guideUid,
        );
    if (mounted) {
      SnackBarHelper.showSuccessSnackBar(context, message: 'Guide blocked.');
      context.pop();
    }
  }

  Future<void> _reportGuide() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report guide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Harassment, spam, etc.',
              ),
            ),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted != true || reasonController.text.trim().isEmpty) {
      reasonController.dispose();
      detailsController.dispose();
      return;
    }

    await ref.read(communicationServiceProvider).reportUser(
          reporterId: user.uid,
          reportedId: widget.guideUid,
          reason: reasonController.text.trim(),
          details: detailsController.text.trim(),
        );
    reasonController.dispose();
    detailsController.dispose();
    if (mounted) {
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Report submitted. Our team will review it.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(publicGuideProvider(widget.guideUid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') _blockGuide();
              if (value == 'report') _reportGuide();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'report', child: Text('Report')),
              PopupMenuItem(value: 'block', child: Text('Block')),
            ],
          ),
        ],
      ),
      body: guideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (guide) {
          if (guide == null) {
            return const Center(child: Text('Guide not available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                        backgroundImage: guide.photoURL != null
                            ? NetworkImage(guide.photoURL!)
                            : null,
                        child: guide.photoURL == null
                            ? Icon(
                                Icons.person_outline,
                                size: 40,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        guide.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (guide.collegeName != null)
                        Text(
                          '${guide.collegeName}${guide.course != null ? ' · ${guide.course}' : ''}${guide.batchYear != null ? ' · ${guide.batchYear}' : ''}',
                          style: GoogleFonts.poppins(color: AppTheme.gray600),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GuideStatsDisplay(
                  stats: guide.stats,
                  verificationBadge: guide.verificationBadge,
                ),
                if (guide.languagesKnown.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Languages',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: guide.languagesKnown
                        .map(
                          (lang) => Chip(
                            label: Text(lang),
                            backgroundColor: AppTheme.gray100,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'Connect safely — phone numbers and emails are never shared.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Voice Call',
                  isLoading: _isRequestingCall,
                  onPressed: () =>
                      _startCall(CommunicationConstants.callTypeVoice),
                ),
                if (guide.settings.videoCallsEnabled) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isRequestingCall
                        ? null
                        : () =>
                            _startCall(CommunicationConstants.callTypeVideo),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video Call'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
