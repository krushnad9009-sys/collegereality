import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';

class CollegeGalleryWidget extends StatelessWidget {
  final List<String> photoUrls;

  const CollegeGalleryWidget({required this.photoUrls, super.key});

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 40, color: AppTheme.gray400),
            const SizedBox(height: 8),
            Text(
              'No photos available',
              style: GoogleFonts.poppins(color: AppTheme.gray500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: photoUrls[index],
              width: 200,
              height: 140,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 200,
                color: AppTheme.gray100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 200,
                color: AppTheme.gray100,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}
