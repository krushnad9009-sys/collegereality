import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../community/services/community_firestore_service.dart';
import '../models/public_guide_profile.dart';
import '../providers/communication_provider.dart';
import '../services/communication_firestore_service.dart';
import '../widgets/guide_stats_display.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../../consultations/widgets/availability_badge.dart';
import '../../consultations/widgets/guide_pricing_card.dart';

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
  bool _isStartingChat = false;

  Future<void> _startPrivateChat(String guideName) async {
    final authUser = ref.read(currentUserProvider);
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    if (authUser == null || userDetail == null) return;
    if (authUser.uid == widget.guideUid) return;

    setState(() => _isStartingChat = true);
    try {
      final conversation =
          await ref.read(communityServiceProvider).getOrCreatePrivateChat(
                currentUser: userDetail,
                peerId: widget.guideUid,
                peerName: guideName,
              );
      if (mounted) {
        context.push(RouteNames.communityChatPath(conversation.id));
      }
    } on CommunityException catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

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
    final tokens = context.tokens;

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
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(publicGuideProvider(widget.guideUid)),
        ),
        data: (guide) {
          if (guide == null) {
            return const AsyncEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Guide not available',
              subtitle: 'This profile may have been removed or is no '
                  'longer offering consultations.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideProfileHeader(guide: guide),
                const SizedBox(height: 24),
                GuideStatsDisplay(
                  stats: guide.stats,
                  verificationBadge: guide.verificationBadge,
                ),
                const SizedBox(height: 20),
                GuidePricingCard(guide: guide),
                if (guide.settings.areasOfExpertise.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ChipSection(
                    title: 'Expertise',
                    values: guide.settings.areasOfExpertise,
                    icon: Icons.workspace_premium_outlined,
                  ),
                ],
                if (guide.languagesKnown.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ChipSection(
                    title: 'Languages',
                    values: guide.languagesKnown,
                    icon: Icons.language_outlined,
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 15, color: tokens.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Connect safely — phone numbers and emails are '
                        'never shared.',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isStartingChat
                      ? null
                      : () => _startPrivateChat(guide.displayName),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Free Private Chat'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
                const SizedBox(height: 12),
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
                      minimumSize: const Size(double.infinity, 52),
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

class _GuideProfileHeader extends StatelessWidget {
  const _GuideProfileHeader({required this.guide});

  final PublicGuideProfile guide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final stats = guide.stats;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.08),
            secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: primary.withValues(alpha: 0.15),
                backgroundImage:
                    guide.photoURL != null ? NetworkImage(guide.photoURL!) : null,
                child: guide.photoURL == null
                    ? Text(
                        guide.displayName.isNotEmpty
                            ? guide.displayName[0].toUpperCase()
                            : 'G',
                        style: AppFonts.plusJakarta(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: guide.presence.isOnline
                          ? PresenceState.online.color
                          : tokens.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  guide.displayName,
                  style: AppFonts.plusJakarta(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              VerificationBadgeWidget(badge: guide.verificationBadge),
            ],
          ),
          if (guide.collegeName != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                guide.collegeName,
                if (guide.course != null) guide.course,
                if (guide.batchYear != null) '${guide.batchYear}',
              ].join(' · '),
              style: AppFonts.plusJakarta(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvailabilityBadge(presence: guide.presence),
              if (stats.totalRatings > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.overallRating.toStringAsFixed(1)} (${stats.totalRatings})',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (guide.settings.areasOfExpertise.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: guide.settings.areasOfExpertise
                  .take(4)
                  .map((e) => _InlineTag(label: e))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small non-interactive tag used inline in the profile header for a quick
/// glance at expertise — visually consistent with [_ChipSection]'s tags.
class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Text(
        label,
        style: AppFonts.plusJakarta(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.values,
    required this.icon,
  });

  final String title;
  final List<String> values;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: tokens.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppFonts.plusJakarta(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (v) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: primary.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    v,
                    style: AppFonts.plusJakarta(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
