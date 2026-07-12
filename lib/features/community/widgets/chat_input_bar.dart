import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showEmoji)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    widget.onSend(
                      text: _emojis[index],
                      messageType: CommunityConstants.messageEmoji,
                    );
                    setState(() => _showEmoji = false);
                  },
                  child: Text(_emojis[index], style: const TextStyle(fontSize: 28)),
                );
              },
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined),
                onPressed: () => setState(() => _showEmoji = !_showEmoji),
              ),
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: () => _pickFile(pdfOnly: false),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => _pickFile(pdfOnly: true),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    filled: true,
                    fillColor: AppTheme.gray100,
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
                icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                onPressed: _sendText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
