import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../community/services/community_firestore_service.dart';
import '../../communication/providers/communication_provider.dart';
import '../../verification/widgets/verification_badge_widget.dart';

class ConnectStudentsSection extends ConsumerStatefulWidget {
  final String collegeId;

  const ConnectStudentsSection({required this.collegeId, super.key});

  @override
  ConsumerState<ConnectStudentsSection> createState() =>
      _ConnectStudentsSectionState();
}

class _ConnectStudentsSectionState extends ConsumerState<ConnectStudentsSection> {
  String? _chattingWith;

  Future<void> _startChat(String peerId, String peerName) async {
    final authUser = ref.read(currentUserProvider);
    final userDetail = ref.read(currentUserDetailProvider).valueOrNull;
    if (authUser == null || userDetail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to connect with students.')),
        );
      }
      return;
    }
    if (authUser.uid == peerId) return;

    setState(() => _chattingWith = peerId);
    try {
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

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final studentsAsync = ref.watch(
      collegeConnectableStudentsProvider((
        collegeId: widget.collegeId,
        excludeUserId: authUser?.uid,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect with Students',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Chat securely with students who allow a public profile. Phone numbers are never shared.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
        ),
        const SizedBox(height: 12),
        studentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Could not load students',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
          ),
          data: (students) {
            if (students.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No students have enabled public profiles at this college yet.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600),
                ),
              );
            }
            return Column(
              children: students.take(8).map((student) {
                final subtitle = [
                  if (student.course != null && student.course!.isNotEmpty)
                    student.course!,
                  if (student.branch != null && student.branch!.isNotEmpty)
                    student.branch!,
                  if (student.batchYear != null) 'Batch ${student.batchYear}',
                ].join(' · ');
                final isLoading = _chattingWith == student.uid;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
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
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.displayName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (student.hasVerificationBadge)
                          VerificationBadgeWidget(
                            badge: student.verificationBadge,
                            iconSize: 14,
                          ),
                      ],
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Text(
                            subtitle,
                            style: GoogleFonts.poppins(fontSize: 11),
                          )
                        : null,
                    trailing: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton.tonal(
                            onPressed: () =>
                                _startChat(student.uid, student.displayName),
                            child: const Text('Chat'),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
