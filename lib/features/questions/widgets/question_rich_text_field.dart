import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
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
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _ToolButton(
                      icon: Icons.format_bold_rounded,
                      tooltip: 'Bold',
                      onTap: () => _wrapSelection(QuestionRichTextUtils.wrapBold),
                    ),
                    _ToolButton(
                      icon: Icons.format_italic_rounded,
                      tooltip: 'Italic',
                      onTap: () => _wrapSelection(QuestionRichTextUtils.wrapItalic),
                    ),
                    _ToolButton(
                      icon: Icons.format_list_bulleted_rounded,
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
                style: AppFonts.plusJakarta(fontSize: 14, color: tokens.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppFonts.plusJakarta(fontSize: 14, color: tokens.textTertiary),
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
          style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary),
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
    final tokens = context.tokens;
    return IconButton(
      icon: Icon(icon, size: 18, color: tokens.textSecondary),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
