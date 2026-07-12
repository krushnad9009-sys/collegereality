import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/community_provider.dart';

class PrivateChatsScreen extends ConsumerWidget {
  const PrivateChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(privateConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Chats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Text(
                'No private chats yet.\nStart from a guide profile or student directory.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.gray600),
              ),
            );
          }
          final userId = ref.read(currentUserDetailProvider).valueOrNull?.uid;
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  userId != null ? chat.displayTitle(userId) : 'Chat',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(chat.lastMessageText ?? 'No messages yet'),
                trailing: Text(
                  chat.lastMessageAt != null
                      ? _shortTime(chat.lastMessageAt!)
                      : '',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
                ),
                onTap: () => context.push(RouteNames.communityChatPath(chat.id)),
              );
            },
          );
        },
      ),
    );
  }

  String _shortTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
