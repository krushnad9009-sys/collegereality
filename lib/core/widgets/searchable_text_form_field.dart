import 'package:flutter/material.dart';

class SearchableTextFormField extends StatefulWidget {
  const SearchableTextFormField({
    super.key,
    required this.controller,
    required this.optionsBuilder,
    this.decoration,
    this.validator,
    this.onChanged,
    this.onSuggestionSelected,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.autovalidateMode,
    this.maxOptionsHeight = 220,
  });

  final TextEditingController controller;
  final List<String> Function(String query) optionsBuilder;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSuggestionSelected;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final double maxOptionsHeight;

  @override
  State<SearchableTextFormField> createState() =>
      _SearchableTextFormFieldState();
}

class _SearchableTextFormFieldState extends State<SearchableTextFormField> {
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false;

  List<String> get _suggestions {
    if (!_showSuggestions) return const [];
    return widget.optionsBuilder(widget.controller.text);
  }

  void _hideSuggestions() {
    if (!_showSuggestions) return;
    setState(() => _showSuggestions = false);
  }

  void _showIfNeeded() {
    if (_showSuggestions) return;
    setState(() => _showSuggestions = true);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus && !_isSelectingSuggestion) {
              Future<void>.delayed(const Duration(milliseconds: 120), () {
                if (mounted && !_isSelectingSuggestion) _hideSuggestions();
              });
            }
          },
          child: TextFormField(
            controller: widget.controller,
            decoration: widget.decoration,
            validator: widget.validator,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autovalidateMode: widget.autovalidateMode,
            onTap: _showIfNeeded,
            onChanged: (value) {
              _showIfNeeded();
              setState(() {});
              widget.onChanged?.call(value);
            },
            onFieldSubmitted: (value) {
              _hideSuggestions();
              widget.onSubmitted?.call(value);
            },
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: BoxConstraints(maxHeight: widget.maxOptionsHeight),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _isSelectingSuggestion = true,
                  onTapCancel: () => _isSelectingSuggestion = false,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      suggestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.controller.text = suggestion;
                      widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                      _isSelectingSuggestion = false;
                      _hideSuggestions();
                      setState(() {});
                      widget.onSuggestionSelected?.call(suggestion);
                      widget.onChanged?.call(suggestion);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
