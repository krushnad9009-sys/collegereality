import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_fonts.dart';
import '../../core/payments/payment_settings.dart';
import '../../core/widgets/index.dart';
import '../../features/admin/services/admin_action_logger.dart';
import '../../features/admin/widgets/admin_shell_layout.dart';

DocumentReference<Map<String, dynamic>> get _settingsDoc => FirebaseFirestore
    .instance
    .collection(PaymentSettings.collection)
    .doc(PaymentSettings.docId);

final _paymentSettingsProvider =
    StreamProvider.autoDispose<PaymentSettings>((ref) {
  return _settingsDoc.snapshots().map(
        (s) => PaymentSettings.fromJson(s.data()),
      );
});

/// Super Admin -> "Payment Gateway": the Razorpay Key ID used for Call
/// Wallet recharges and consultation payments. Applied to the next order
/// with no app update. Writes `app_config/payment_settings` (Super
/// Admin-only in firestore.rules).
class SuperAdminPaymentSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminPaymentSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminPaymentSettingsScreen> createState() =>
      _SuperAdminPaymentSettingsScreenState();
}

class _SuperAdminPaymentSettingsScreenState
    extends ConsumerState<SuperAdminPaymentSettingsScreen> {
  PaymentSettings? _saved;
  final _keyId = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _keyId.dispose();
    super.dispose();
  }

  void _hydrate(PaymentSettings s) {
    _saved = s;
    _keyId.text = s.razorpayKeyId;
  }

  String get _draftKey => _keyId.text.trim();
  bool get _valid => PaymentSettings.isValidKeyIdOrEmpty(_draftKey);
  bool get _dirty => _saved != null && _draftKey != _saved!.razorpayKeyId;

  Future<void> _save() async {
    if (!_valid) return;
    final draft = PaymentSettings(razorpayKeyId: _draftKey);
    if (draft.isLiveKey && !(_saved?.isLiveKey ?? false)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch to a LIVE key?'),
          content: const Text(
            'Real money will be charged from the next payment. The '
            'RAZORPAY_KEY_SECRET in Secret Manager must be the secret of '
            'this same live key, or every payment will fail.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Use live key'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    try {
      await _settingsDoc.set({
        ...draft.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      try {
        await AdminActionLogger().log(
          action: 'payments.settings.update',
          targetId: PaymentSettings.docId,
          targetType: PaymentSettings.collection,
          metadata: draft.toJson(),
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() => _saved = draft);
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Payment settings saved — used from the next payment.',
      );
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: 'Could not save: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_paymentSettingsProvider);
    final live = async.valueOrNull;
    if (live != null && _saved == null) _hydrate(live);
    final tokens = context.tokens;
    final draft = PaymentSettings(razorpayKeyId: _draftKey);

    return AdminShellLayout(
      title: 'Payment Gateway',
      showBack: false,
      isAdminUser: true,
      child: _saved == null
          ? Center(
              child: async.hasError
                  ? Text('Could not load settings: ${async.error}')
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Razorpay powers Call Wallet recharges and consultation '
                  'payments. The Key ID set here is used from the next '
                  'payment — no app update needed. Leave it empty to use '
                  'the key deployed with Cloud Functions.',
                  style: AppFonts.plusJakarta(
                      fontSize: 13, color: tokens.textSecondary),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Razorpay Key ID',
                                style: AppFonts.plusJakarta(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            if (_valid && _draftKey.isNotEmpty)
                              Chip(
                                label: Text(draft.isLiveKey ? 'LIVE' : 'TEST'),
                                backgroundColor: draft.isLiveKey
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _keyId,
                          onChanged: (_) => setState(() {}),
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'Key ID',
                            hintText: 'rzp_live_XXXXXXXXXXXXXX',
                            errorText: _valid
                                ? null
                                : 'Format: rzp_test_… or rzp_live_…',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Never paste the Key Secret here. The secret stays '
                          'in Secret Manager (RAZORPAY_KEY_SECRET) and must '
                          'belong to this same key — switching to a new key '
                          'means updating that secret too.',
                          style: AppFonts.plusJakarta(
                              fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: _dirty ? 'Save changes' : 'Saved',
                        isLoading: _saving,
                        onPressed: _dirty && _valid ? _save : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _dirty && !_saving
                          ? () => setState(() => _hydrate(_saved!))
                          : null,
                      child: const Text('Discard'),
                    ),
                  ],
                ),
                if (live?.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Last changed ${live!.updatedAt!.toLocal()}',
                      style: AppFonts.plusJakarta(
                          fontSize: 12, color: tokens.textTertiary),
                    ),
                  ),
              ],
            ),
    );
  }
}
