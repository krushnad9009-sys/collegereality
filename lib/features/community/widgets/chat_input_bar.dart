import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/constants/community_constants.dart';

typedef ChatSubmitCallback = void Function({
  required String text,
  required String messageType,
  Uint8List? attachmentBytes,
  String? attachmentName,
});

class ChatInputBar extends StatefulWidget {
  final ChatSubmitCallback onSend;
  final ValueChanged<bool>? onTypingChanged;

  const ChatInputBar({
    required this.onSend,
    this.onTypingChanged,
    super.key,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _showEmoji = false;

  static const _emojis = ['😀', '😂', '👍', '🙏', '🎓', '🔥', '❤️', '👏', '🤔', '😍'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool pdfOnly}) async {
    final result = await FilePicker.platform.pickFiles(
      type: pdfOnly ? FileType.custom : FileType.image,
      allowedExtensions: pdfOnly ? ['pdf'] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.bytes!.length > CommunityConstants.maxAttachmentBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 8MB)')),
        );
      }
      return;
    }

    widget.onSend(
      text: pdfOnly ? '📄 PDF' : '📷 Photo',
      messageType: pdfOnly ? CommunityConstants.messagePdf : CommunityConstants.messageImage,
      attachmentBytes: file.bytes,
      attachmentName: file.name,
    );
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text: text, messageType: CommunityConstants.messageText);
    _controller.clear();
    widget.onTypingChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showEmoji)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border(top: BorderSide(color: tokens.borderSubtle)),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _emojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    widget.onSend(
                      text: _emojis[index],
                      messageType: CommunityConstants.messageEmoji,
                    );
                    setState(() => _showEmoji = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(_emojis[index], style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(
            8,
            8,
            12,
            MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            border: Border(top: BorderSide(color: tokens.borderSubtle)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                  color: tokens.textTertiary,
                ),
                onPressed: () => setState(() => _showEmoji = !_showEmoji),
              ),
              IconButton(
                icon: Icon(Icons.image_outlined, color: tokens.textTertiary),
                onPressed: () => _pickFile(pdfOnly: false),
              ),
              IconButton(
                icon: Icon(Icons.picture_as_pdf_outlined, color: tokens.textTertiary),
                onPressed: () => _pickFile(pdfOnly: true),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppFonts.plusJakarta(
                    fontSize: 14.5,
                    color: tokens.textPrimary,
                  ),
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: AppFonts.plusJakarta(
                      fontSize: 14.5,
                      color: tokens.textTertiary,
                    ),
                    filled: true,
                    fillColor: tokens.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (_) => widget.onTypingChanged?.call(true),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send_rounded, color: primary),
                onPressed: _sendText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
