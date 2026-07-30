import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../models/college_model.dart';
import '../providers/college_provider.dart';

class CollegeAutocompleteField extends ConsumerStatefulWidget {
  final String? selectedCollegeId;
  final String? selectedCollegeName;
  final ValueChanged<CollegeModel?> onChanged;

  const CollegeAutocompleteField({
    required this.onChanged,
    this.selectedCollegeId,
    this.selectedCollegeName,
    super.key,
  });

  @override
  ConsumerState<CollegeAutocompleteField> createState() =>
      _CollegeAutocompleteFieldState();
}

class _CollegeAutocompleteFieldState
    extends ConsumerState<CollegeAutocompleteField> {
  late final TextEditingController _controller;
  String _lastQuery = '';
  String _debouncedQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedCollegeName ?? '');
  }

  @override
  void didUpdateWidget(CollegeAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCollegeName != oldWidget.selectedCollegeName &&
        widget.selectedCollegeName != _controller.text) {
      _controller.text = widget.selectedCollegeName ?? '';
      _debouncedQuery = widget.selectedCollegeName?.trim() ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typedQuery = _controller.text.trim();
    final query = _debouncedQuery;
    final suggestionsAsync = query.isNotEmpty &&
            query != (widget.selectedCollegeName ?? '').trim()
        ? ref.watch(collegeInstantSuggestProvider(query))
        : const AsyncValue<List<CollegeModel>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'College',
            hintText: 'Search from 47,000+ colleges...',
            filled: true,
            fillColor: AppTheme.gray100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: widget.selectedCollegeId != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _debounce?.cancel();
                      _controller.clear();
                      widget.onChanged(null);
                      setState(() {
                        _debouncedQuery = '';
                        _lastQuery = '';
                      });
                    },
                  )
                : const Icon(Icons.search),
          ),
          onChanged: (_) {
            if (_controller.text.trim() != _lastQuery) {
              widget.onChanged(null);
            }
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              setState(() => _debouncedQuery = _controller.text.trim());
            });
            setState(() {});
          },
        ),
        suggestionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Could not search colleges',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
            ),
          ),
          data: (colleges) {
            if (colleges.isEmpty || query.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
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
                itemCount: colleges.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final college = colleges[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      college.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      college.locationLabel,
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    onTap: () {
                      _debounce?.cancel();
                      _lastQuery = college.name;
                      _controller.text = college.name;
                      _debouncedQuery = college.name;
                      widget.onChanged(college);
                      setState(() {});
                    },
                  );
                },
              ),
            );
          },
        ),
        if (widget.selectedCollegeId == null && typedQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Pick your college from suggestions',
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
            ),
          ),
      ],
    );
  }
}
