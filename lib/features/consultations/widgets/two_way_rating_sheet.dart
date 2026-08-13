import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';
import '../models/consultation_rating_model.dart';
import '../providers/consultation_provider.dart';

/// Post-consultation rating — criteria differ by direction (student rating
/// a guide vs. a guide rating a student) per the product spec, but both
/// flow through the same widget/collection. Only shown once the
/// consultation is `completed` (enforced server-side by firestore.rules,
/// this UI just doesn't offer the option otherwise — see
/// ConsultationModel.canRate).
Future<void> showTwoWayRatingSheet({
  required BuildContext context,
  required String consultationId,
  required String raterId,
  required String raterRole,
  required String rateeId,
  required String rateeLabel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TwoWayRatingSheet(
      consultationId: consultationId,
      raterId: raterId,
      raterRole: raterRole,
      rateeId: rateeId,
      rateeLabel: rateeLabel,
    ),
  );
}

class TwoWayRatingSheet extends ConsumerStatefulWidget {
  final String consultationId;
  final String raterId;
  final String raterRole;
  final String rateeId;
  final String rateeLabel;

  const TwoWayRatingSheet({
    required this.consultationId,
    required this.raterId,
    required this.raterRole,
    required this.rateeId,
    required this.rateeLabel,
    super.key,
  });

  @override
  ConsumerState<TwoWayRatingSheet> createState() => _TwoWayRatingSheetState();
}

class _TwoWayRatingSheetState extends ConsumerState<TwoWayRatingSheet> {
  int _overall = 5;
  int _communication = 5;
  int _c2 = 5;
  int _c3 = 5;
  int _c4 = 5;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final labels = ConsultationRatingLabels.forRole(widget.raterRole);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.pageH,
        right: AppSpacing.pageH,
        top: AppSpacing.pageH,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.pageH,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate ${widget.rateeLabel}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Your identity stays private — only aggregate ratings are shown publicly.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _starRow('Overall', _overall, (v) => setState(() => _overall = v)),
          _starRow('Communication', _communication, (v) => setState(() => _communication = v)),
          _starRow(labels.criterion2, _c2, (v) => setState(() => _c2 = v)),
          _starRow(labels.criterion3, _c3, (v) => setState(() => _c3 = v)),
          _starRow(labels.criterion4, _c4, (v) => setState(() => _c4 = v)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Submit rating',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _starRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          for (var i = 1; i <= 5; i++)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
              iconSize: 20,
              icon: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
              ),
              onPressed: () => onChanged(i),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(consultationServiceProvider).submitRating(
            consultationId: widget.consultationId,
            raterId: widget.raterId,
            raterRole: widget.raterRole,
            rateeId: widget.rateeId,
            overall: _overall,
            communication: _communication,
            criterion2: _c2,
            criterion3: _c3,
            criterion4: _c4,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarHelper.showSuccessSnackBar(context, message: 'Thanks for rating!');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(context, message: 'Could not submit rating: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
