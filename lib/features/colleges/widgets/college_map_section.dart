import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../core/widgets/premium_components.dart';

class CollegeMapSection extends StatelessWidget {
  final String mapsLink;
  final String? address;
  final double? latitude;
  final double? longitude;

  const CollegeMapSection({
    required this.mapsLink,
    this.address,
    this.latitude,
    this.longitude,
    super.key,
  });

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(mapsLink);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return PremiumCard(
      radius: tokens.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.7),
                ),
                child: Icon(Icons.map_outlined, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: AppFonts.plusJakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (address != null && address!.trim().isNotEmpty)
                      Text(
                        address!,
                        style: AppFonts.plusJakarta(
                          fontSize: 13,
                          color: tokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 10),
            Text(
              '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
              style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in Google Maps'),
            ),
          ),
        ],
      ),
    );
  }
}
