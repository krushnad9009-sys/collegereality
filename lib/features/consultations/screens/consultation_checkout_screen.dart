import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../communication/models/guide_stats_model.dart';
import '../../communication/providers/communication_provider.dart';
import '../models/consultation_model.dart';
import '../providers/consultation_provider.dart';
import '../services/consultation_service.dart';
import '../services/payment_service.dart';
import '../widgets/availability_badge.dart';

class _PriceOption {
  final String type;
  final int minutes;
  final int pricePaise;
  final String label;
  const _PriceOption(this.type, this.minutes, this.pricePaise, this.label);
}

class ConsultationCheckoutScreen extends ConsumerStatefulWidget {
  final String guideId;
  const ConsultationCheckoutScreen({required this.guideId, super.key});

  @override
  ConsumerState<ConsultationCheckoutScreen> createState() =>
      _ConsultationCheckoutScreenState();
}

class _ConsultationCheckoutScreenState
    extends ConsumerState<ConsultationCheckoutScreen> {
  _PriceOption? _selected;
  bool _processing;
  String? _error;

  _ConsultationCheckoutScreenState() : _processing = false;

  List<_PriceOption> _optionsFor(GuideCommunicationSettings s) {
    final options = <_PriceOption>[];
    if (s.chatAvailable && s.chatPricePaise > 0) {
      options.add(_PriceOption(
        'chat',
        s.chatDurationMinutes,
        s.chatPricePaise,
        '💬 Chat · ${s.chatDurationMinutes} min',
      ));
    }
    if (s.callAvailable) {
      for (final o in s.callPricing) {
        if (o.pricePaise <= 0) continue;
        options.add(_PriceOption(
          o.type,
          o.minutes,
          o.pricePaise,
          '${o.type == 'video' ? '📹 Video' : '📞 Call'} · ${o.minutes} min',
        ));
      }
    }
    return options;
  }

  Future<void> _pay(String studentId, String guideId) async {
    final option = _selected;
    if (option == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    final consultationService = ref.read(consultationServiceProvider);
    final paymentService = ref.read(paymentServiceProvider);
    final authUser = ref.read(currentUserProvider);

    ConsultationModel? consultation;
    try {
      consultation = await consultationService.requestConsultation(
        studentId: studentId,
        guideId: guideId,
        type: option.type,
        durationMinutes: option.minutes,
        grossPaise: option.pricePaise,
      );

      final order = await paymentService.createOrder(consultation.id);

      final result = await paymentService.openCheckout(
        order: order,
        description: option.label,
        contactEmail: authUser?.email ?? '',
        contactPhone: authUser?.phoneNumber ?? '',
      );

      await paymentService.verifyPayment(
        consultationId: consultation.id,
        razorpayOrderId: result.orderId ?? order.razorpayOrderId,
        razorpayPaymentId: result.paymentId ?? '',
        razorpaySignature: result.signature ?? '',
      );

      if (!mounted) return;
      context.go(RouteNames.consultationRoomPath(consultation.id));
    } on ConsultationException catch (e) {
      setState(() => _error = e.message);
    } on PaymentException catch (e) {
      setState(() => _error = e.message);
      // Payment didn't complete — let the student retry or cancel; the
      // consultation stays in payment_pending and expires automatically
      // (see functions/src/scheduled.js) rather than being silently stuck.
      if (consultation != null) {
        await consultationService.cancelConsultation(
          consultationId: consultation.id,
          reason: 'payment_failed_or_cancelled',
        );
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(publicGuideProvider(widget.guideId));
    final currentUser = ref.watch(currentUserProvider);
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a consultation')),
      body: AsyncStateView(
        value: guideAsync,
        builder: (guide) {
          if (guide == null) {
            return const AsyncEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Guide not found',
              subtitle: 'This profile may have been removed.',
            );
          }
          if (!guide.isEligibleGuide) {
            return const AsyncEmptyView(
              icon: Icons.verified_outlined,
              title: 'Not available',
              subtitle: 'This guide is no longer a verified student/alumni.',
            );
          }
          final options = _optionsFor(guide.settings);
          if (options.isEmpty) {
            return const AsyncEmptyView(
              icon: Icons.event_busy_outlined,
              title: 'Not taking consultations right now',
              subtitle: 'This guide hasn\'t set up chat/call pricing yet.',
            );
          }
          if (currentUser?.uid == guide.uid) {
            return const AsyncEmptyView(
              icon: Icons.block_outlined,
              title: 'Not available',
              subtitle: 'You cannot book a consultation with yourself.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        backgroundImage: guide.photoURL != null
                            ? NetworkImage(guide.photoURL!)
                            : null,
                        child: guide.photoURL == null
                            ? Text(
                                guide.displayName.isNotEmpty
                                    ? guide.displayName[0].toUpperCase()
                                    : 'G',
                                style: AppFonts.plusJakarta(
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text(
                                  guide.displayName,
                                  style: AppFonts.plusJakarta(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded, size: 16, color: primary),
                            ]),
                            if (guide.collegeName != null)
                              Text(
                                guide.collegeName!,
                                style: AppFonts.plusJakarta(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            AvailabilityBadge(presence: guide.presence),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: 'Choose a consultation', subtitle: null),
                const SizedBox(height: 10),
                for (final option in options) ...[
                  _PriceOptionCard(
                    option: option,
                    selected: _selected == option,
                    onTap: () => setState(() => _selected = option),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_selected != null) ...[
                  const SizedBox(height: 14),
                  _CheckoutSummaryCard(option: _selected!, guideName: guide.displayName),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 18, color: AppTheme.errorColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppFonts.plusJakarta(
                              color: AppTheme.errorColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (kIsWeb)
                  const AsyncEmptyView(
                    icon: Icons.phone_iphone_outlined,
                    title: 'Pay on the mobile app',
                    subtitle:
                        'Secure checkout is available on the College Reality mobile app for now.',
                  )
                else
                  PrimaryButton(
                    label: _selected == null
                        ? 'Select an option'
                        : 'Pay ₹${(_selected!.pricePaise / 100).toStringAsFixed(0)}',
                    isLoading: _processing,
                    onPressed: (_selected == null || currentUser == null)
                        ? null
                        : () => _pay(currentUser.uid, guide.uid),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A clear, card-based breakdown of what the student is about to pay for —
/// shown once a consultation option is picked, before the Pay button.
class _CheckoutSummaryCard extends StatelessWidget {
  const _CheckoutSummaryCard({required this.option, required this.guideName});

  final _PriceOption option;
  final String guideName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: tokens.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order summary',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tokens.textTertiary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow(context, 'With', guideName),
          const SizedBox(height: 8),
          _summaryRow(context, 'Session', option.label),
          const SizedBox(height: 8),
          _summaryRow(context, 'Duration', '${option.minutes} minutes'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: tokens.borderSubtle),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppFonts.plusJakarta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              Text(
                '₹${(option.pricePaise / 100).toStringAsFixed(0)}',
                style: AppFonts.plusJakarta(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    final tokens = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.plusJakarta(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: tokens.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppFonts.plusJakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PriceOptionCard extends StatelessWidget {
  const _PriceOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PriceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: selected ? primary : tokens.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : tokens.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: AppFonts.plusJakarta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            Text(
              '₹${(option.pricePaise / 100).toStringAsFixed(0)}',
              style: AppFonts.plusJakarta(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: selected ? primary : tokens.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
