import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../community/services/community_firestore_service.dart';
import '../../communication/providers/communication_provider.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../services/student_chat_service.dart';

final studentChatServiceProvider = Provider<StudentChatService>((ref) {
  return StudentChatService();
});

class TalkToStudentsScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const TalkToStudentsScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<TalkToStudentsScreen> createState() =>
      _TalkToStudentsScreenState();
}

class _TalkToStudentsScreenState extends ConsumerState<TalkToStudentsScreen> {
  String? _chattingWith;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logPageView());
  }

  Future<void> _logPageView() async {
    final authUser = ref.read(currentUserProvider);
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    if (authUser == null) return;

    await ref.read(studentChatServiceProvider).logIntent(
          collegeId: widget.collegeId,
          collegeName: widget.collegeName,
          seekerId: authUser.uid,
          seekerName: userDetail?.displayName ?? '',
          action: 'view_list',
        );
  }

  Future<void> _startChat(String peerId, String peerName) async {
    final authUser = ref.read(currentUserProvider);
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    if (authUser == null || userDetail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to chat with students.')),
        );
      }
      return;
    }
    if (authUser.uid == peerId) return;

    setState(() => _chattingWith = peerId);
    try {
      await ref.read(studentChatServiceProvider).logIntent(
            collegeId: widget.collegeId,
            collegeName: widget.collegeName,
            seekerId: authUser.uid,
            seekerName: userDetail.displayName ?? '',
            action: 'start_chat',
            peerId: peerId,
            peerName: peerName,
          );

      final conversation =
          await ref.read(communityServiceProvider).getOrCreatePrivateChat(
                currentUser: userDetail,
                peerId: peerId,
                peerName: peerName,
              );
      if (mounted) {
        context.push(RouteNames.communityChatPath(conversation.id));
      }
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _chattingWith = null);
    }
  }

  String _badgeLabel(String badge) {
    return VerificationConstants.badgeLabel(badge);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final studentsAsync = ref.watch(
      collegeConnectableStudentsProvider((
        collegeId: widget.collegeId,
        excludeUserId: authUser?.uid,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to Students'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.12),
                  AppTheme.secondaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.collegeName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chat with verified students and alumni. Ask about campus life, placements, hostel, and admissions — phone numbers are never shared.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.gray700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          studentsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'Could not load students: $e',
                style: GoogleFonts.poppins(color: AppTheme.errorColor),
              ),
            ),
            data: (students) {
              if (students.isEmpty) {
                return _EmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${students.length} verified student${students.length == 1 ? '' : 's'} available',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...students.map((student) {
                    final subtitle = [
                      if (student.course != null && student.course!.isNotEmpty)
                        student.course!,
                      if (student.branch != null && student.branch!.isNotEmpty)
                        student.branch!,
                      if (student.batchYear != null) 'Batch ${student.batchYear}',
                    ].join(' · ');
                    final isLoading = _chattingWith == student.uid;
                    final badgeLabel = _badgeLabel(student.verificationBadge);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              backgroundImage: student.photoURL != null
                                  ? NetworkImage(student.photoURL!)
                                  : null,
                              child: student.photoURL == null
                                  ? Text(
                                      student.displayName.isNotEmpty
                                          ? student.displayName[0].toUpperCase()
                                          : 'S',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.displayName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.gray600,
                                      ),
                                    ),
                                  if (badgeLabel.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        VerificationBadgeWidget(
                                          badge: student.verificationBadge,
                                          iconSize: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          badgeLabel,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            isLoading
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _startChat(
                                      student.uid,
                                      student.displayName,
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                    label: const Text('Chat'),
                                  ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppTheme.gray400),
          const SizedBox(height: 12),
          Text(
            'No students available yet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Verified students and alumni at this college can enable a public profile to appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
          ),
        ],
      ),
    );
  }
}
