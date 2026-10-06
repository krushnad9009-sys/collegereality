import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/widgets/index.dart';
import '../services/verification_firestore_service.dart';

/// Pick exactly [VerificationConstants.requiredGuideVerificationDocs]
/// distinct document types (College ID card, fee receipt, marksheet, ...)
/// and a photo/PDF for each. Reports every change through [onChanged] with
/// the documents that have a file picked; the parent decides when that's
/// complete. Shared by the guide verification sheet and the guide
/// onboarding wizard's document step.
class GuideDocumentsPicker extends StatefulWidget {
  final ValueChanged<List<GuideVerificationDoc>> onChanged;
  final bool enabled;

  const GuideDocumentsPicker({
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  State<GuideDocumentsPicker> createState() => _GuideDocumentsPickerState();
}

class _GuideDocumentsPickerState extends State<GuideDocumentsPicker> {
  static const _required = VerificationConstants.requiredGuideVerificationDocs;

  final _selected = <String>[];
  final _files = <String, ({Uint8List bytes, String name})>{};

  void _emit() {
    widget.onChanged([
      for (final type in _selected)
        if (_files[type] != null)
          GuideVerificationDoc(
            documentType: type,
            bytes: _files[type]!.bytes,
            fileName: _files[type]!.name,
          ),
    ]);
  }

  void _toggleType(String typeId, bool checked) {
    setState(() {
      if (checked) {
        if (_selected.length >= _required) return;
        _selected.add(typeId);
      } else {
        _selected.remove(typeId);
        _files.remove(typeId);
      }
    });
    _emit();
  }

  Future<void> _pickFor(String typeId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: VerificationConstants.allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length >= VerificationConstants.maxFileBytes) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          message: 'That file is too large. Each document must be under 10 MB.',
        );
      }
      return;
    }
    setState(() => _files[typeId] = (bytes: bytes, name: file.name));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final selectionFull = _selected.length >= _required;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select exactly $_required document types and upload a photo or '
          'PDF for each. ${_selected.length}/$_required selected.',
          style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textSecondary),
        ),
        const SizedBox(height: 8),
        for (final doc in VerificationConstants.guideVerificationDocumentTypes)
          Builder(builder: (context) {
            final id = doc['id']!;
            final isChecked = _selected.contains(id);
            final picked = _files[id];
            final locked = !isChecked && selectionFull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isChecked,
                  // Lock the remaining options once enough are chosen.
                  onChanged: (!widget.enabled || locked)
                      ? null
                      : (v) => _toggleType(id, v ?? false),
                  title: Text(
                    doc['label']!,
                    style: AppFonts.plusJakarta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: locked ? tokens.textTertiary : tokens.textPrimary,
                    ),
                  ),
                ),
                if (isChecked)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: widget.enabled ? () => _pickFor(id) : null,
                      icon: Icon(
                        picked != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        size: 18,
                        color: picked != null ? AppTheme.accentColor : null,
                      ),
                      label: Text(
                        picked?.name ?? 'Upload file (photo/PDF)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            );
          }),
      ],
    );
  }
}
