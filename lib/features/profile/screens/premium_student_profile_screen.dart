import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Student not found'));
          }

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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumProfileHeader(profile: profile),
                      const SizedBox(height: 20),
                      TrustScoreCard(trust: profile.trust),
                      const SizedBox(height: 20),
                      _InfoSection(
                        icon: Icons.school_outlined,
                        title: 'College',
                        value: profile.collegeName ?? 'Not set',
                      ),
                      if (profile.course != null)
                        _InfoSection(
                          icon: Icons.menu_book_outlined,
                          title: 'Course',
                          value: profile.course!,
                        ),
                      if (profile.branch != null && profile.branch!.isNotEmpty)
                        _InfoSection(
                          icon: Icons.account_tree_outlined,
                          title: 'Branch',
                          value: profile.branch!,
                        ),
                      if (profile.batchYear != null)
                        _InfoSection(
                          icon: Icons.calendar_today_outlined,
                          title: 'Year',
                          value: '${profile.batchYear}',
                        ),
                      if (profile.languagesKnown.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Languages',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.languagesKnown
                              .map((l) => Chip(label: Text(l)))
                              .toList(),
                        ),
                      ],
                      if (profile.aboutMe != null &&
                          profile.aboutMe!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'About Me',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.aboutMe!,
                          style: GoogleFonts.poppins(
                            color: AppTheme.gray700,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (profile.interests.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Interests',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.interests
                              .map(
                                (i) => Chip(
                                  label: Text(i),
                                  backgroundColor:
                                      AppTheme.secondaryColor.withValues(alpha: 0.12),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (!isOwnProfile)
                        PrimaryButton(
                          label: 'Chat',
                          isLoading: _isStartingChat,
                          onPressed: () => _startChat(profile.displayName),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Phone numbers and emails are never shown on student profiles.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.gray500,
                        ),
                        textAlign: TextAlign.center,
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

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray700),
            ),
          ),
        ],
      ),
    );
  }
}
