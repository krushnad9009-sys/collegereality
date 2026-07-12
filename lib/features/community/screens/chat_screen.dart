import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../models/chat_conversation_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (conversation) {
        if (conversation == null || user == null) {
          return const Scaffold(body: Center(child: Text('Chat unavailable')));
        }

        final peerId = conversation.peerIdFor(user.uid);
        final presenceAsync = peerId != null ? ref.watch(presenceProvider(peerId)) : null;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.displayTitle(user.uid),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (presenceAsync != null)
                  presenceAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (p) => PresenceIndicator(presence: p),
                  ),
              ],
            ),
            actions: [
              if (peerId != null)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') _reportPeer(peerId);
                    if (v == 'block') _blockPeer(peerId);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'report', child: Text('Report')),
                    PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Say hello! Free private student chat.',
                          style: GoogleFonts.poppins(color: AppTheme.gray600),
                        ),
                      );
                    }
                    final peerReadId = peerId != null
                        ? conversation.readReceipts[peerId]
                        : null;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                        return MessageBubble(
                          message: msg,
                          isMine: msg.senderId == user.uid,
                          peerLastReadMessageId: peerReadId,
                        );
                      },
                    );
                  },
                ),
              ),
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
        );
      },
    );
  }
}
