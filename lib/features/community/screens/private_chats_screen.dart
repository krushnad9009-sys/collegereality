import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/community_provider.dart';

class PrivateChatsScreen extends ConsumerWidget {
  const PrivateChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(privateConversationsProvider);
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: tokens.surfaceElevated,
        title: Text(
          'Private Chats',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: AsyncStateView(
        value: chatsAsync,
        showSkeleton: true,
        isEmpty: (chats) => chats.isEmpty,
        emptyBuilder: () => AsyncEmptyView(
          icon: Icons.chat_outlined,
          title: 'No private chats yet',
          subtitle:
              'Start a conversation from a guide profile or the student directory.',
          action: OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.guidesDirectory),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Browse Guides'),
          ),
        ),
        builder: (chats) {
          final userId = ref.read(currentUserDetailProvider).valueOrNull?.uid;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final title =
                  userId != null ? chat.displayTitle(userId) : 'Chat';
              final preview = chat.lastMessageText ?? 'No messages yet';
              final timeLabel = chat.lastMessageAt != null
                  ? _shortTime(chat.lastMessageAt!)
                  : '';

              return PremiumCard(
                padding: EdgeInsets.zero,
                radius: tokens.cardRadius,
                onTap: () => context.push(RouteNames.communityChatPath(chat.id)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      preview,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: timeLabel.isNotEmpty
                      ? Text(
                          timeLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: tokens.textTertiary,
                          ),
                        )
                      : null,
                ),
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
