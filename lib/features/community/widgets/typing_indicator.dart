import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
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
        ? '${typingNames.first} is typing'
        : 'Several people are typing';

    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: tokens.textTertiary,
            ),
          ),
          const SizedBox(width: 6),
          const _TypingDots(),
        ],
      ),
    );
  }
}

/// Three softly pulsing dots — a purely decorative animation local to this
/// widget's build, echoing the bubble-tail rhythm of the chat surface.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 18,
      height: 6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value - (i * 0.2)) % 1.0;
              final pulse = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Opacity(
                  opacity: 0.35 + 0.65 * pulse,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
