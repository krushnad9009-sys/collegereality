import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/chat_conversation_model.dart';

class TypingIndicator extends StatelessWidget {
  final ChatConversationModel? conversation;
  final String currentUserId;

  const TypingIndicator({
    required this.conversation,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) return const SizedBox.shrink();

    final typingNames = <String>[];
    final now = DateTime.now();
    conversation!.typingUsers.forEach((userId, timestamp) {
      if (userId == currentUserId) return;
      final parsed = DateTime.tryParse(timestamp);
      if (parsed != null && now.difference(parsed).inSeconds < 5) {
        typingNames.add(conversation!.participantNames[userId] ?? 'Someone');
      }
    });

    if (typingNames.isEmpty) return const SizedBox.shrink();

    final label = typingNames.length == 1
        ? '${typingNames.first} is typing...'
        : 'Several people are typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppTheme.gray600,
        ),
      ),
    );
  }
}
