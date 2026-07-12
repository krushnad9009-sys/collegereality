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
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final suggestionsAsync = query.length >= 2 && query != widget.selectedCollegeName
        ? ref.watch(collegeAutocompleteProvider(query))
        : const AsyncValue<List<CollegeModel>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'College',
            hintText: 'Search from 40,000+ colleges...',
            filled: true,
            fillColor: AppTheme.gray100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: widget.selectedCollegeId != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged(null);
                      setState(() {});
                    },
                  )
                : const Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {
            if (_controller.text.trim() != _lastQuery) {
              widget.onChanged(null);
            }
          }),
        ),
        suggestionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Could not search colleges',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
            ),
          ),
          data: (colleges) {
            if (colleges.isEmpty || query.length < 2) {
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
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                      _lastQuery = college.name;
                      _controller.text = college.name;
                      widget.onChanged(college);
                      setState(() {});
                    },
                  );
                },
              ),
            );
          },
        ),
        if (widget.selectedCollegeId == null && query.length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Type at least 2 characters and pick your college from results',
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
            ),
          ),
      ],
    );
  }
}
