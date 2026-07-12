import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/communication_constants.dart';

class LanguageMultiSelectField extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const LanguageMultiSelectField({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  Future<void> _openPicker(BuildContext context) async {
    final temp = Set<String>.from(selected);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Languages Known',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CommunicationConstants.supportedLanguages
                            .map((lang) {
                          final isSelected = temp.contains(lang);
                          return FilterChip(
                            label: Text(lang),
                            selected: isSelected,
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  temp.add(lang);
                                } else {
                                  temp.remove(lang);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onChanged(temp.toList()..sort());
                        Navigator.pop(context);
                      },
                      child: const Text('Save Languages'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages Known',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.gray100,
              prefixIcon: const Icon(Icons.translate_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              selected.isEmpty
                  ? 'Select languages you speak'
                  : selected.join(', '),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: selected.isEmpty ? AppTheme.gray500 : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
