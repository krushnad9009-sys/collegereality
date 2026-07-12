import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final bg = isMine
        ? AppTheme.primaryColor
        : AppTheme.gray100;
    final fg = isMine ? Colors.white : AppTheme.gray800;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                message.senderName,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            _content(fg),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isMine ? Colors.white70 : AppTheme.gray500,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _isReadByPeer() ? Icons.done_all : Icons.done,
                    size: 14,
                    color: _isReadByPeer() ? Colors.lightBlueAccent : Colors.white70,
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

  Widget _content(Color fg) {
    switch (message.messageType) {
      case CommunityConstants.messageImage:
        if (message.attachmentUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.attachmentUrl!,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text('Image unavailable', style: TextStyle(color: fg)),
            ),
          );
        }
        return Text('📷 Photo', style: TextStyle(color: fg));
      case CommunityConstants.messagePdf:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.attachmentName ?? 'Document.pdf',
                style: GoogleFonts.poppins(color: fg),
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
          style: GoogleFonts.poppins(color: fg, fontSize: 14),
        );
    }
  }

  String _timeLabel(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
