import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Community'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Connect with students — free & private',
            style: GoogleFonts.poppins(color: AppTheme.gray600),
          ),
          const SizedBox(height: 20),
          _CommunityTile(
            icon: Icons.chat_bubble_outline,
            title: 'Private Chats',
            subtitle: 'Free 1:1 messaging with read receipts',
            color: AppTheme.primaryColor,
            onTap: () => context.push(RouteNames.communityPrivateChats),
          ),
          _CommunityTile(
            icon: Icons.school_outlined,
            title: 'College Discussion',
            subtitle: 'Talk with students at your college',
            color: AppTheme.secondaryColor,
            onTap: () => _openRoom(context, ref, CommunityConstants.typeCollege),
          ),
          _CommunityTile(
            icon: Icons.menu_book_outlined,
            title: 'Branch Discussion',
            subtitle: 'Course-specific conversations',
            color: AppTheme.accentColor,
            onTap: () => _openRoom(context, ref, CommunityConstants.typeBranch),
          ),
          _CommunityTile(
            icon: Icons.support_agent_outlined,
            title: 'Ask Seniors',
            subtitle: 'Get advice from senior students',
            color: AppTheme.warningColor,
            onTap: () => context.push(RouteNames.communityAskSeniors),
          ),
          _CommunityTile(
            icon: Icons.quiz_outlined,
            title: 'Student Q&A',
            subtitle: 'Questions and answers board',
            color: const Color(0xFF7C3AED),
            onTap: () => context.push(RouteNames.communityQa),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
