import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../providers/community_provider.dart';
import '../services/community_firestore_service.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/presence_indicator.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({required this.conversationId, super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  Timer? _typingTimer;
  final _scrollController = ScrollController();
  String _searchQuery = '';
  List<ChatMessageModel>? _searchResults;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setOnline(true));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _setOnline(false);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setOnline(bool online) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;
    await ref.read(communityServiceProvider).updatePresence(user.uid, isOnline: online);
  }

  void _onTypingChanged(bool typing) {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;
    _typingTimer?.cancel();
    ref.read(communityServiceProvider).setTyping(
          conversationId: widget.conversationId,
          userId: user.uid,
          isTyping: typing,
        );
    if (typing) {
      _typingTimer = Timer(CommunityConstants.typingTimeout, () {
        ref.read(communityServiceProvider).setTyping(
              conversationId: widget.conversationId,
              userId: user.uid,
              isTyping: false,
            );
      });
    }
  }

  Future<void> _send({
    required String text,
    required String messageType,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(communityServiceProvider).sendMessage(
            conversationId: widget.conversationId,
            sender: user,
            text: text,
            messageType: messageType,
            attachmentBytes: attachmentBytes,
            attachmentName: attachmentName,
          );
    } on CommunityException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    }
  }

  Future<void> _markRead(ChatConversationModel conversation, List messages) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null || messages.isEmpty) return;
    final last = messages.last;
    await ref.read(communityServiceProvider).markConversationRead(
          conversationId: widget.conversationId,
          userId: user.uid,
          lastMessageId: last.id,
        );
  }

  Future<void> _reportPeer(String? peerId) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null || peerId == null) return;
    await ref.read(communityServiceProvider).reportContent(
          reporterId: user.uid,
          reportedId: peerId,
          reason: 'Inappropriate chat behavior',
          conversationId: widget.conversationId,
        );
    if (mounted) {
      SnackBarHelper.showSuccessSnackBar(context, message: 'Report submitted.');
    }
  }

  Future<void> _blockPeer(String? peerId) async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user == null || peerId == null) return;
    await ref.read(communityServiceProvider).blockUser(
          blockerId: user.uid,
          blockedId: peerId,
        );
    if (mounted) context.pop();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _searching = query.trim().isNotEmpty;
      _searchResults = null;
    });
    if (query.trim().isEmpty) return;
    final results =
        await ref.read(communityServiceProvider).searchMessagesInConversation(
              conversationId: widget.conversationId,
              query: query,
            );
    if (mounted) setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    ref.listen(messagesProvider(widget.conversationId), (previous, next) {
      next.whenData((messages) {
        final conversation =
            ref.read(conversationProvider(widget.conversationId)).valueOrNull;
        final currentUser = ref.read(currentUserDetailProvider).valueOrNull;
        if (conversation != null && currentUser != null && messages.isNotEmpty) {
          _markRead(conversation, messages);
        }
      });
    });

    return conversationAsync.when(
      loading: () => const Scaffold(
        body: AsyncLoadingView(message: 'Loading conversation…'),
      ),
      error: (e, _) => Scaffold(
        body: AsyncErrorView.fromError(e),
      ),
      data: (conversation) {
        if (conversation == null || user == null) {
          return Scaffold(
            body: AsyncEmptyView(
              icon: Icons.forum_outlined,
              title: 'Unable to load this conversation',
              subtitle: 'The chat may have been removed or you no longer have access.',
            ),
          );
        }

        final peerId = conversation.peerIdFor(user.uid);
        final presenceAsync = peerId != null ? ref.watch(presenceProvider(peerId)) : null;

        return Scaffold(
          backgroundColor: tokens.surfaceMuted,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0.5,
            backgroundColor: tokens.surfaceElevated,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.displayTitle(user.uid),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                if (presenceAsync != null)
                  presenceAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (p) => PresenceIndicator(presence: p),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
                onPressed: () {
                  if (_searching) {
                    _runSearch('');
                  } else {
                    _showSearchSheet(context);
                  }
                },
              ),
              if (peerId != null)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'profile') {
                      context.push(RouteNames.studentProfilePath(peerId));
                    }
                    if (v == 'report') _reportPeer(peerId);
                    if (v == 'block') _blockPeer(peerId);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'profile', child: Text('View Profile')),
                    PopupMenuItem(value: 'report', child: Text('Report')),
                    PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              if (_searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search messages…',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: tokens.textTertiary,
                      ),
                      filled: true,
                      fillColor: tokens.surfaceElevated,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: tokens.textTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.buttonRadius),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.buttonRadius),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.buttonRadius),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: _runSearch,
                  ),
                ),
              Expanded(
                child: _searching
                    ? _buildSearchResults(user)
                    : messagesAsync.when(
                        loading: () => const AsyncLoadingView(),
                        error: (e, _) => AsyncErrorView.fromError(e),
                        data: (messages) {
                          if (messages.isEmpty) {
                            return AsyncEmptyView(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Start the conversation',
                              subtitle:
                                  'Say hello! Free private student chat.',
                            );
                          }
                          final peerReadId = peerId != null
                              ? conversation.readReceipts[peerId]
                              : null;
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.sm,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              if (index == messages.length - 1) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scrollController.hasClients) {
                                    _scrollController.jumpTo(
                                      _scrollController.position.maxScrollExtent,
                                    );
                                  }
                                });
                              }
                              final msg = messages[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: MessageBubble(
                                  message: msg,
                                  isMine: msg.senderId == user.uid,
                                  peerLastReadMessageId: peerReadId,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              if (!_searching)
                Container(
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    border: Border(
                      top: BorderSide(color: tokens.borderSubtle),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TypingIndicator(
                        conversation: conversation,
                        currentUserId: user.uid,
                      ),
                      ChatInputBar(
                        onSend: _send,
                        onTypingChanged: _onTypingChanged,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchSheet(BuildContext context) {
    setState(() => _searching = true);
  }

  Widget _buildSearchResults(UserModel user) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    if (_searchQuery.trim().isEmpty) {
      return Center(
        child: Text(
          'Type to search this conversation',
          style: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        ),
      );
    }
    if (_searchResults == null) {
      return const AsyncLoadingView(message: 'Searching…');
    }
    if (_searchResults!.isEmpty) {
      return AsyncEmptyView(
        icon: Icons.search_off_rounded,
        title: 'No matches found',
        subtitle: 'No messages match "$_searchQuery"',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final msg = _searchResults![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MessageBubble(
            message: msg,
            isMine: msg.senderId == user.uid,
          ),
        );
      },
    );
  }
}
