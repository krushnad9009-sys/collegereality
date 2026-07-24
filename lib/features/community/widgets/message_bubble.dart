import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/community_constants.dart';
import '../models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final String? peerLastReadMessageId;

  const MessageBubble({
    required this.message,
    required this.isMine,
    this.peerLastReadMessageId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isMine
        ? AppTheme.primaryColor
        : (isDark ? tokens.surfaceElevated : tokens.surfaceElevated);
    final fg = isMine ? Colors.white : tokens.textPrimary;
    final borderColor = isMine
        ? Colors.transparent
        : tokens.borderSubtle;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isMine ? AppSpacing.radiusMd : 4),
            bottomRight: Radius.circular(isMine ? 4 : AppSpacing.radiusMd),
          ),
          border: Border.all(color: borderColor),
          boxShadow: isMine
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  message.senderName,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            _content(fg, textTheme),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.createdAt),
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isMine ? Colors.white70 : tokens.textTertiary,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    _isReadByPeer() ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: _isReadByPeer()
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isReadByPeer() {
    if (peerLastReadMessageId == null) return false;
    return peerLastReadMessageId == message.id;
  }

  Widget _content(Color fg, TextTheme textTheme) {
    switch (message.messageType) {
      case CommunityConstants.messageImage:
        if (message.attachmentUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Image.network(
              message.attachmentUrl!,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.broken_image_outlined,
                color: fg,
                size: 20,
              ),
            ),
          );
        }
        return Text('📷 Photo', style: TextStyle(color: fg));
      case CommunityConstants.messagePdf:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: fg, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                message.attachmentName ?? 'Document.pdf',
                style: textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
          ],
        );
      case CommunityConstants.messageEmoji:
        return Text(
          message.text,
          style: const TextStyle(fontSize: 28),
        );
      default:
        return Text(
          message.text,
          style: textTheme.bodyMedium?.copyWith(
            color: fg,
            height: 1.45,
          ),
        );
    }
  }

  String _timeLabel(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
