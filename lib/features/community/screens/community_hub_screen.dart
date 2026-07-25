import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/community_provider.dart';
import '../services/community_firestore_service.dart';

class CommunityHubScreen extends ConsumerWidget {
  const CommunityHubScreen({super.key});

  Future<void> _openRoom(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;
    try {
      final conversation = await ref.read(communityServiceProvider).getOrCreateRoom(
            type: type,
            user: user,
          );
      if (context.mounted) {
        context.push(RouteNames.communityChatPath(conversation.id));
      }
    } on CommunityException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.gray900 : const Color(0xFFF3F5FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: FadeInSection(
                  delayMs: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF312E81),
                                const Color(0xFF1E3A5F),
                                AppTheme.gray800,
                              ]
                            : [
                                AppTheme.primaryColor,
                                const Color(0xFF6366F1),
                                AppTheme.secondaryColor,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(
                            alpha: isDark ? 0.2 : 0.32,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Student Community',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.45,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Connect with students — free, private & verified',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            _HeroPill(icon: Icons.lock_outline_rounded, label: 'Private'),
                            const SizedBox(width: 8),
                            _HeroPill(icon: Icons.verified_rounded, label: 'Verified'),
                            const SizedBox(width: 8),
                            _HeroPill(icon: Icons.chat_rounded, label: 'Free'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                96,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInSection(
                    delayMs: 60,
                    child: SectionHeader(
                      title: 'Connect',
                      subtitle: 'Chat, discuss, and get advice from peers',
                    ),
                  ),
                  FadeInSection(
                    delayMs: 80,
                    child: _CommunityTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Private Chats',
                      subtitle: 'Free 1:1 messaging with read receipts',
                      color: AppTheme.primaryColor,
                      onTap: () => context.push(RouteNames.communityPrivateChats),
                    ),
                  ),
                  FadeInSection(
                    delayMs: 100,
                    child: _CommunityTile(
                      icon: Icons.forum_outlined,
                      title: 'College Discussion Feed',
                      subtitle: 'Posts, Q&A and campus updates in one place',
                      color: AppTheme.secondaryColor,
                      onTap: () => context.push(RouteNames.communityDiscussionFeed),
                    ),
                  ),
                  FadeInSection(
                    delayMs: 120,
                    child: _CommunityTile(
                      icon: Icons.school_outlined,
                      title: 'College Discussion',
                      subtitle: 'Talk with students at your college',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _openRoom(context, ref, CommunityConstants.typeCollege),
                    ),
                  ),
                  FadeInSection(
                    delayMs: 140,
                    child: _CommunityTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Branch Discussion',
                      subtitle: 'Course-specific conversations',
                      color: AppTheme.accentColor,
                      onTap: () => _openRoom(context, ref, CommunityConstants.typeBranch),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  FadeInSection(
                    delayMs: 160,
                    child: const SectionHeader(
                      title: 'Get Help',
                      subtitle: 'Ask seniors and browse student Q&A',
                    ),
                  ),
                  FadeInSection(
                    delayMs: 180,
                    child: _CommunityTile(
                      icon: Icons.support_agent_outlined,
                      title: 'Ask Seniors',
                      subtitle: 'Get advice from senior students',
                      color: AppTheme.warningColor,
                      onTap: () => context.push(RouteNames.communityAskSeniors),
                    ),
                  ),
                  FadeInSection(
                    delayMs: 200,
                    child: _CommunityTile(
                      icon: Icons.quiz_outlined,
                      title: 'Student Q&A',
                      subtitle: 'Questions and answers board',
                      color: const Color(0xFFEC4899),
                      onTap: () => context.push(RouteNames.communityQa),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CommunityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        radius: tokens.cardRadius,
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
