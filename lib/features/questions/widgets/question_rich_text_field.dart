import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../utils/question_rich_text_utils.dart';

class QuestionRichTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;

  const QuestionRichTextField({
    required this.controller,
    this.hint = 'Write here...',
    this.maxLines = 4,
    this.maxLength,
    super.key,
  });

  @override
  State<QuestionRichTextField> createState() => _QuestionRichTextFieldState();
}

class _QuestionRichTextFieldState extends State<QuestionRichTextField> {
  void _wrapSelection(String Function(String) wrap) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (!selection.isValid) return;
    final selected = selection.textInside(text);
    if (selected.isEmpty) return;
    final wrapped = wrap(selected);
    final newText = text.replaceRange(selection.start, selection.end, wrapped);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + wrapped.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _ToolButton(
                      icon: Icons.format_bold,
                      tooltip: 'Bold',
                      onTap: () => _wrapSelection(QuestionRichTextUtils.wrapBold),
                    ),
                    _ToolButton(
                      icon: Icons.format_italic,
                      tooltip: 'Italic',
                      onTap: () => _wrapSelection(QuestionRichTextUtils.wrapItalic),
                    ),
                    _ToolButton(
                      icon: Icons.format_list_bulleted,
                      tooltip: 'Bullet',
                      onTap: () {
                        final text = widget.controller.text;
                        widget.controller.text = text.isEmpty
                            ? QuestionRichTextUtils.bulletLine('')
                            : '$text\n${QuestionRichTextUtils.bulletLine('')}';
                      },
                    ),
                  ],
                ),
              ),
              TextField(
                controller: widget.controller,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use **bold**, *italic*, and - bullets. Mentions: @[Name](userId)',
          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
