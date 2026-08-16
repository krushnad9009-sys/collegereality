import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';

class CollegeGalleryWidget extends StatelessWidget {
  final List<String> photoUrls;

  const CollegeGalleryWidget({required this.photoUrls, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (photoUrls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 32, color: tokens.textTertiary),
            const SizedBox(height: 8),
            Text(
              'No photos yet',
              style: AppFonts.plusJakarta(
                color: tokens.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'The college hasn\'t added campus photos',
              style: AppFonts.plusJakarta(
                color: tokens.textTertiary,
                fontSize: 12,
              ),
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
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            child: CachedNetworkImage(
              imageUrl: photoUrls[index],
              width: 200,
              height: 140,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                width: 200,
                color: tokens.surfaceMuted,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                width: 200,
                color: tokens.surfaceMuted,
                child: Icon(Icons.broken_image_outlined,
                    color: tokens.textTertiary),
              ),
            ),
          );
        },
      ),
    );
  }
}
