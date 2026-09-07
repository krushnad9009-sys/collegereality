import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

/// Renders the AI Automated Verification Agent's verdict for a single
/// student-document or college-listing request. Fed generic primitives so
/// both `VerificationRequestModel` and `CollegeRequestModel` can use it.
class AiVerdictPanel extends StatelessWidget {
  /// 'accept' | 'reject' | 'flag' | null (agent hasn't run yet).
  final String? decision;
  final double confidence;
  final String summary;
  final List<String> flags;

  /// Sub-scores 0..1 and string verdicts. Numeric entries render as bars.
  final Map<String, dynamic> checks;

  /// Redacted values the agent read off the document (student docs only).
  final Map<String, dynamic> extracted;

  final String? model;
  final DateTime? reviewedAt;

  const AiVerdictPanel({
    required this.decision,
    required this.confidence,
    required this.summary,
    this.flags = const [],
    this.checks = const {},
    this.extracted = const {},
    this.model,
    this.reviewedAt,
    super.key,
  });

  ({Color color, IconData icon, String label}) get _style {
    switch (decision) {
      case 'accept':
        return (
          color: const Color(0xFF059669),
          icon: Icons.check_circle_rounded,
          label: 'AI: AUTO-ACCEPT',
        );
      case 'reject':
        return (
          color: const Color(0xFFDC2626),
          icon: Icons.cancel_rounded,
          label: 'AI: AUTO-REJECT',
        );
      case 'flag':
        return (
          color: const Color(0xFFD97706),
          icon: Icons.flag_rounded,
          label: 'AI: NEEDS REVIEW',
        );
      default:
        return (
          color: const Color(0xFF64748B),
          icon: Icons.hourglass_empty_rounded,
          label: 'AI: not reviewed yet',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = _style;
    final pending = decision == null;

    final numericChecks = <MapEntry<String, double>>[];
    final stringChecks = <MapEntry<String, String>>[];
    checks.forEach((k, v) {
      if (v is num) {
        numericChecks.add(MapEntry(_humanize(k), v.toDouble().clamp(0, 1)));
      } else if (v is String && v.trim().isNotEmpty && k != 'concerns') {
        stringChecks.add(MapEntry(_humanize(k), v));
      }
    });
    final concerns =
        (checks['concerns'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(s.icon, size: 18, color: s.color),
              const SizedBox(width: 6),
              Text(
                s.label,
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: s.color,
                ),
              ),
              const Spacer(),
              if (!pending)
                Text(
                  '${(confidence * 100).round()}%',
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: s.color,
                  ),
                ),
            ],
          ),
          if (!pending) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence.clamp(0, 1),
                minHeight: 6,
                backgroundColor: s.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(s.color),
              ),
            ),
          ],
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary,
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                height: 1.4,
                color: tokens.textPrimary,
              ),
            ),
          ],
          if (extracted.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MiniHeader('Read from document'),
            const SizedBox(height: 4),
            ...extracted.entries
                .where((e) => e.value != null && '${e.value}'.trim().isNotEmpty)
                .map((e) => _KvRow(_humanize(e.key), '${e.value}')),
          ],
          if (numericChecks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MiniHeader('Signal scores'),
            const SizedBox(height: 4),
            ...numericChecks.map(
              (e) => _ScoreRow(label: e.key, value: e.value),
            ),
          ],
          if (stringChecks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...stringChecks.map((e) => _KvRow(e.key, _humanize(e.value))),
          ],
          if (concerns.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MiniHeader('Concerns'),
            const SizedBox(height: 2),
            ...concerns.map(
              (c) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $c',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          if (flags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: flags
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFD97706).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _humanize(f),
                        style: AppFonts.plusJakarta(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (!pending && (model != null || reviewedAt != null)) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (model != null) model,
                if (reviewedAt != null) _relative(reviewedAt!),
              ].join(' · '),
              style: AppFonts.plusJakarta(
                fontSize: 10.5,
                color: tokens.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _humanize(String key) {
    if (key.isEmpty) return key;
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _MiniHeader extends StatelessWidget {
  final String text;
  const _MiniHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.plusJakarta(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: context.tokens.textTertiary,
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  final String k;
  final String v;
  const _KvRow(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textPrimary),
          children: [
            TextSpan(
              text: '$k: ',
              style: TextStyle(color: tokens.textTertiary),
            ),
            TextSpan(
              text: v,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;
  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Green when high, amber mid, red low — for "good" signals. Tamper is
    // inverted conceptually but the raw score bar is still informative.
    final color = value >= 0.7
        ? const Color(0xFF059669)
        : value >= 0.45
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 11.5,
                color: tokens.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: tokens.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toStringAsFixed(2),
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
