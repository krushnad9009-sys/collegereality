import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../community/services/community_firestore_service.dart';
import '../providers/student_profile_provider.dart';
import '../widgets/premium_profile_header.dart';
import '../widgets/trust_score_card.dart';

class PremiumStudentProfileScreen extends ConsumerStatefulWidget {
  final String studentUid;

  const PremiumStudentProfileScreen({required this.studentUid, super.key});

  @override
  ConsumerState<PremiumStudentProfileScreen> createState() =>
      _PremiumStudentProfileScreenState();
}

class _PremiumStudentProfileScreenState
    extends ConsumerState<PremiumStudentProfileScreen> {
  bool _isStartingChat = false;

  Future<void> _startChat(String peerName) async {
    final authUser = ref.read(currentUserProvider);
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    if (authUser == null || userDetail == null) return;
    if (authUser.uid == widget.studentUid) return;

    setState(() => _isStartingChat = true);
    try {
      final conversation =
          await ref.read(communityServiceProvider).getOrCreatePrivateChat(
                currentUser: userDetail,
                peerId: widget.studentUid,
                peerName: peerName,
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

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final profileAsync =
        ref.watch(premiumStudentProfileProvider(widget.studentUid));
    final isOwnProfile = authUser?.uid == widget.studentUid;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView.fromError(
          e,
          onRetry: () =>
              ref.invalidate(premiumStudentProfileProvider(widget.studentUid)),
        ),
        data: (profile) {
          if (profile == null) {
            return const AsyncEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Student not found',
              subtitle: 'This profile may have been removed.',
            );
          }

          final tokens = context.tokens;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => context.pop(),
                ),
                title: const Text('Student Profile'),
                actions: [
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.go(RouteNames.profile),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageH,
                    0,
                    AppSpacing.pageH,
                    AppSpacing.section,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumProfileHeader(profile: profile),
                      const SizedBox(height: AppSpacing.xl),
                      TrustScoreCard(trust: profile.trust),
                      const SizedBox(height: AppSpacing.xl),
                      PremiumCard(
                        radius: tokens.cardRadius,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(title: 'Details'),
                            _DetailRow(
                              icon: Icons.school_outlined,
                              label: 'College',
                              value: profile.collegeName ?? 'Not set',
                            ),
                            if (profile.course != null)
                              _DetailRow(
                                icon: Icons.menu_book_outlined,
                                label: 'Course',
                                value: profile.course!,
                              ),
                            if (profile.branch != null &&
                                profile.branch!.isNotEmpty)
                              _DetailRow(
                                icon: Icons.account_tree_outlined,
                                label: 'Branch',
                                value: profile.branch!,
                              ),
                            if (profile.batchYear != null)
                              _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Year',
                                value: '${profile.batchYear}',
                                showDivider: false,
                              ),
                          ],
                        ),
                      ),
                      if (profile.languagesKnown.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _TagSection(
                          title: 'Languages',
                          values: profile.languagesKnown,
                          tinted: false,
                        ),
                      ],
                      if (profile.aboutMe != null &&
                          profile.aboutMe!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        PremiumCard(
                          radius: tokens.cardRadius,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: 'About Me'),
                              Text(
                                profile.aboutMe!,
                                style: AppFonts.plusJakarta(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textSecondary,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (profile.interests.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _TagSection(
                          title: 'Interests',
                          values: profile.interests,
                          tinted: true,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      if (!isOwnProfile)
                        PrimaryButton(
                          label: 'Chat',
                          isLoading: _isStartingChat,
                          onPressed: () => _startChat(profile.displayName),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: tokens.textTertiary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Phone numbers and emails are never shown on '
                              'student profiles.',
                              style: AppFonts.plusJakarta(
                                fontSize: 11,
                                color: tokens.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single label/value row inside the Details [PremiumCard] — a tinted
/// icon badge, a field label, and its value.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.6),
                ),
                child: Icon(icon, size: 16, color: primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakarta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: tokens.borderSubtle, height: 1),
      ],
    );
  }
}

/// A titled Wrap of tag chips, used for both Languages (neutral) and
/// Interests (tinted with the brand color).
class _TagSection extends StatelessWidget {
  final String title;
  final List<String> values;
  final bool tinted;

  const _TagSection({
    required this.title,
    required this.values,
    required this.tinted,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: tinted
                    ? primary.withValues(alpha: 0.08)
                    : tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: tinted
                      ? primary.withValues(alpha: 0.18)
                      : tokens.borderSubtle,
                ),
              ),
              child: Text(
                v,
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tinted ? primary : tokens.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
