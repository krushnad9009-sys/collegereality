import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_theme.dart';

class YearPickerField extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int firstYear;
  final int lastYear;

  YearPickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstYear = 2010,
    int? lastYear,
    super.key,
  }) : lastYear = lastYear ?? DateTime.now().year + 6;

  Future<void> _pickYear(BuildContext context) async {
    final years = List.generate(
      lastYear - firstYear + 1,
      (i) => lastYear - i,
    );

    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Select Batch Year',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = year == value;
                return ListTile(
                  title: Text(
                    '$year',
                    style: GoogleFonts.poppins(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () => Navigator.pop(context, year),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (value != null)
              TextButton(
                onPressed: () => Navigator.pop(context, -1),
                child: const Text('Clear'),
              ),
          ],
        );
      },
    );

    if (selected == null) return;
    if (selected == -1) {
      onChanged(null);
    } else {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickYear(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select batch year',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gray800
                  : AppTheme.gray100,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.gray200),
              ),
            ),
            child: Text(
              value != null ? '$value' : 'Tap to select year',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: value != null ? null : AppTheme.gray500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
