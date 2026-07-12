import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_theme.dart';

class ReviewMediaGallery extends StatelessWidget {
  final List<String> photoUrls;
  final List<String> videoUrls;

  const ReviewMediaGallery({
    required this.photoUrls,
    required this.videoUrls,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty && videoUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photoUrls.isNotEmpty) ...[
          Text(
            'Photos',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: photoUrls[index],
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
        if (videoUrls.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Videos',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...videoUrls.map(
            (url) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Watch video'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
