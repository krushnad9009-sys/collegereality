import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_theme.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (address != null && address!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              address!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.gray700,
                height: 1.4,
              ),
            ),
          ],
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 6),
            Text(
              '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
            ),
          ],
          const SizedBox(height: 12),
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
